#if os(iOS)
import CoreGraphics
import Foundation
import MetalKit
import QuartzCore

final class MetalWaveformRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private let configLock = NSLock()
    private var config = MetalWaveformConfig()
    private var vertexBuffers = [MTLBuffer?](repeating: nil, count: 3)
    private var vertexBufferIndex = 0
    private var vertexBufferOffset = 0
    private let vertexBufferLength = 512 * 1024

    private var amplitudes: [CGFloat] = []
    private var particles: [MetalWaveformParticle] = []
    private var displayedMotionIntensity: Double = 0
    private var displayedColorLevel: Double = 0
    private var previousMotionIntensity: Double = 0
    private var particleBudgetAccumulator: Double = 0
    private var renderOffset: TimeInterval = 0
    private var lastFrameTime = CACurrentMediaTime()

    func attach(to view: MTKView) {
        guard let device = view.device else { return }
        self.device = device
        commandQueue = device.makeCommandQueue()
        pipelineState = makePipelineState(device: device, pixelFormat: view.colorPixelFormat)
        view.delegate = self
    }

    func update(_ nextConfig: MetalWaveformConfig) {
        configLock.lock()
        config = nextConfig
        configLock.unlock()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandQueue,
              let pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        let now = CACurrentMediaTime()
        let delta = min(1.0 / 12.0, max(1.0 / 120.0, now - lastFrameTime))
        lastFrameTime = now

        configLock.lock()
        let frameConfig = config
        configLock.unlock()

        updateSimulation(config: frameConfig, delta: delta)
        beginVertexBufferFrame()

        encoder.setRenderPipelineState(pipelineState)
        drawWaveLayers(encoder: encoder, drawableSize: view.drawableSize, config: frameConfig)
        drawParticles(encoder: encoder, drawableSize: view.drawableSize)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func updateSimulation(config: MetalWaveformConfig, delta: TimeInterval) {
        let rawMotion = min(1.0, max(0.0, config.motionIntensity))
        let waveformMotion = min(1.0, pow(rawMotion, 0.62) * 1.38)
        let particleMotion = min(1.0, pow(rawMotion, 0.55) * 1.85)
        let motion = waveformMotion
        displayedMotionIntensity += (motion - displayedMotionIntensity) * min(1.0, delta * 7.2)
        displayedColorLevel += (targetColorLevel(for: config.reactionState) - displayedColorLevel) * min(1.0, delta * 1.35)

        if config.isAnimating {
            renderOffset += delta
            let targetAmplitudes = AudioMotionSpectrumAnalyzer.amplitudes(
                playbackTime: config.playbackTime + renderOffset,
                isPlaying: true,
                audioLevel: config.audioLevel,
                motionIntensity: displayedMotionIntensity,
                trackSeed: config.trackSeed
            )
            updateAmplitudes(target: targetAmplitudes, delta: delta)
            spawnParticlesIfNeeded(
                currentMotion: particleMotion,
                audioLevel: config.audioLevel,
                reactionState: config.reactionState,
                delta: delta
            )
        } else {
            if amplitudes.isEmpty {
                amplitudes = Array(repeating: 0.02, count: AudioMotionSpectrumAnalyzer.binCount)
            } else {
                amplitudes = amplitudes.map { $0 * 0.80 }
            }
        }

        updateParticles(delta: delta)
        previousMotionIntensity = motion
    }

    private func updateAmplitudes(target: [CGFloat], delta: TimeInterval) {
        guard !target.isEmpty else { return }

        if amplitudes.count != target.count {
            amplitudes = target
            return
        }

        let response = CGFloat(min(1.0, max(0.0, delta * 4.2)))
        amplitudes = zip(amplitudes, target).map { current, next in
            current + (next - current) * response
        }
    }

    private func drawWaveLayers(
        encoder: MTLRenderCommandEncoder,
        drawableSize: CGSize,
        config: MetalWaveformConfig
    ) {
        drawRing(
            encoder: encoder,
            drawableSize: drawableSize,
            radiusScale: 1.08,
            thicknessScale: 1.45,
            alpha: 0.20,
            audioLevel: config.audioLevel
        )
        drawRing(
            encoder: encoder,
            drawableSize: drawableSize,
            radiusScale: 1.03,
            thicknessScale: 0.72,
            alpha: 0.34,
            audioLevel: config.audioLevel
        )
        drawRing(
            encoder: encoder,
            drawableSize: drawableSize,
            radiusScale: 0.96,
            thicknessScale: 0.92,
            alpha: 0.54,
            audioLevel: config.audioLevel
        )
        drawRing(
            encoder: encoder,
            drawableSize: drawableSize,
            radiusScale: 0.88,
            thicknessScale: 1.10,
            alpha: 0.92,
            audioLevel: config.audioLevel
        )
    }

    private func drawRing(
        encoder: MTLRenderCommandEncoder,
        drawableSize: CGSize,
        radiusScale: CGFloat,
        thicknessScale: CGFloat,
        alpha: Float,
        audioLevel: Double
    ) {
        let vertices = ringVertices(
            drawableSize: drawableSize,
            radiusScale: radiusScale,
            thicknessScale: thicknessScale,
            alpha: alpha,
            audioLevel: audioLevel
        )
        guard vertices.count >= 4 else { return }
        encodeVertices(vertices, primitive: .triangleStrip, encoder: encoder)
    }

    private func ringVertices(
        drawableSize: CGSize,
        radiusScale: CGFloat,
        thicknessScale: CGFloat,
        alpha: Float,
        audioLevel: Double
    ) -> [MetalWaveformVertex] {
        let amplitudeCount = amplitudes.count
        guard amplitudeCount >= 4, drawableSize.width > 1, drawableSize.height > 1 else { return [] }

        let minDimension = min(drawableSize.width, drawableSize.height)
        let center = CGPoint(x: drawableSize.width / 2, y: drawableSize.height / 2)
        let motion = CGFloat(min(1.0, max(0.0, displayedMotionIntensity)))
        let audio = CGFloat(min(1.0, max(0.0, audioLevel)))
        let innerRadius = minDimension * 0.305 * radiusScale
        let maxThickness = minDimension * (0.055 + audio * 0.092 + motion * 0.225) * thicknessScale
        let colors = waveformPalette()
        let segmentCount = min(256, max(96, amplitudeCount * 2))

        var vertices: [MetalWaveformVertex] = []
        vertices.reserveCapacity((segmentCount + 1) * 2)

        for index in 0...segmentCount {
            let progress = CGFloat(index % segmentCount) / CGFloat(segmentCount)
            let fractionalIndex = progress * CGFloat(amplitudeCount)
            let angle = progress * 2.0 * .pi
            let amplitude = interpolatedAmplitude(at: fractionalIndex)
            let outerRadius = innerRadius + pow(amplitude, 0.72) * maxThickness
            let innerPoint = CGPoint(
                x: center.x + cos(angle) * innerRadius,
                y: center.y + sin(angle) * innerRadius
            )
            let outerPoint = CGPoint(
                x: center.x + cos(angle) * outerRadius,
                y: center.y + sin(angle) * outerRadius
            )
            let color = gradientColor(colors: colors, progress: Double(progress), alpha: alpha)
            vertices.append(MetalWaveformVertex(position: normalizedPoint(innerPoint, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(outerPoint, size: drawableSize), color: color))
        }

        return vertices
    }

    private func interpolatedAmplitude(at fractionalIndex: CGFloat) -> CGFloat {
        let count = amplitudes.count
        guard count > 0 else { return 0 }

        let lowerIndex = Int(floor(fractionalIndex)) % count
        let upperIndex = (lowerIndex + 1) % count
        let fraction = fractionalIndex - floor(fractionalIndex)
        let amount = fraction * fraction * (3.0 - 2.0 * fraction)
        let lower = smoothedAmplitude(at: lowerIndex)
        let upper = smoothedAmplitude(at: upperIndex)
        return lower + (upper - lower) * amount
    }

    private func smoothedAmplitude(at index: Int) -> CGFloat {
        let count = amplitudes.count
        guard count > 0 else { return 0 }

        let previous = amplitudes[(index - 1 + count) % count]
        let current = amplitudes[index]
        let next = amplitudes[(index + 1) % count]
        return previous * 0.22 + current * 0.56 + next * 0.22
    }

    private func drawParticles(encoder: MTLRenderCommandEncoder, drawableSize: CGSize) {
        guard !particles.isEmpty, drawableSize.width > 1, drawableSize.height > 1 else { return }

        let center = CGPoint(x: drawableSize.width / 2, y: drawableSize.height / 2)
        var vertices: [MetalWaveformVertex] = []
        vertices.reserveCapacity(particles.count * 6)

        for particle in particles {
            let progress = max(0, particle.life / particle.maxLife)
            let point = CGPoint(
                x: center.x + cos(particle.angle) * particle.radius,
                y: center.y + sin(particle.angle) * particle.radius
            )
            let twinkle = 0.72 + 0.28 * sin((1 - progress) * 8.0 + particle.twinklePhase)
            let halfSize = particle.size * (0.55 + progress * 0.50)
            let color = hsvToRGB(
                hue: particle.hue,
                saturation: particle.saturation,
                brightness: 1,
                alpha: Float(progress * twinkle * 0.98)
            )
            let radial = CGPoint(x: cos(particle.angle), y: sin(particle.angle))
            let tangent = CGPoint(x: -radial.y, y: radial.x)
            let long = halfSize * (1.15 + progress * 0.55)
            let short = halfSize * 0.46
            let top = CGPoint(x: point.x + radial.x * long, y: point.y + radial.y * long)
            let right = CGPoint(x: point.x + tangent.x * short, y: point.y + tangent.y * short)
            let bottom = CGPoint(x: point.x - radial.x * long, y: point.y - radial.y * long)
            let left = CGPoint(x: point.x - tangent.x * short, y: point.y - tangent.y * short)

            vertices.append(MetalWaveformVertex(position: normalizedPoint(top, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(left, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(right, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(right, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(left, size: drawableSize), color: color))
            vertices.append(MetalWaveformVertex(position: normalizedPoint(bottom, size: drawableSize), color: color))
        }

        encodeVertices(vertices, primitive: .triangle, encoder: encoder)
    }

    private func beginVertexBufferFrame() {
        vertexBufferIndex = (vertexBufferIndex + 1) % vertexBuffers.count
        vertexBufferOffset = 0

        if vertexBuffers[vertexBufferIndex] == nil {
            vertexBuffers[vertexBufferIndex] = device?.makeBuffer(
                length: vertexBufferLength,
                options: .storageModeShared
            )
        }
    }

    private func encodeVertices(
        _ vertices: [MetalWaveformVertex],
        primitive: MTLPrimitiveType,
        encoder: MTLRenderCommandEncoder
    ) {
        guard !vertices.isEmpty,
              let buffer = vertexBuffers[vertexBufferIndex] else {
            return
        }

        let byteCount = vertices.count * MemoryLayout<MetalWaveformVertex>.stride
        let alignedOffset = ((vertexBufferOffset + 255) / 256) * 256
        guard alignedOffset + byteCount <= buffer.length else {
            return
        }

        vertices.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            buffer.contents()
                .advanced(by: alignedOffset)
                .copyMemory(from: baseAddress, byteCount: byteCount)
            encoder.setVertexBuffer(buffer, offset: alignedOffset, index: 0)
            encoder.drawPrimitives(type: primitive, vertexStart: 0, vertexCount: vertices.count)
        }
        vertexBufferOffset = alignedOffset + byteCount
    }

    private func spawnParticlesIfNeeded(
        currentMotion: Double,
        audioLevel: Double,
        reactionState: HowTag,
        delta: TimeInterval
    ) {
        let surge = max(0, currentMotion - previousMotionIntensity * 0.50)
        let audioSpark = max(0, audioLevel - 0.34)
        let motionEnergy = max(currentMotion * 2.40, surge * 4.2)
        guard motionEnergy > 0.004 || audioSpark > 0.045 else { return }

        particleBudgetAccumulator += delta * (18 + motionEnergy * 310 + audioSpark * 52)
        let spawnCount = min(44, Int(particleBudgetAccumulator))
        guard spawnCount > 0 else { return }
        particleBudgetAccumulator -= Double(spawnCount)

        let baseRadius = CGFloat(88 + currentMotion * 42)
        let maxParticles = 420

        for _ in 0..<spawnCount where particles.count < maxParticles {
            let hue = particleHue(for: reactionState)
            particles.append(MetalWaveformParticle(
                angle: CGFloat.random(in: 0..<(2 * .pi)),
                radius: baseRadius + CGFloat.random(in: -16...32),
                velocity: CGFloat.random(in: 28...92) * CGFloat(0.90 + currentMotion),
                angularVelocity: CGFloat.random(in: -0.52...0.52),
                size: CGFloat.random(in: 1.45...3.65),
                life: CGFloat.random(in: 0.82...1.70),
                hue: hue,
                saturation: particleSaturation(for: reactionState),
                twinklePhase: CGFloat.random(in: 0...(2 * .pi))
            ))
        }
    }

    private func updateParticles(delta: TimeInterval) {
        let dt = CGFloat(delta)
        particles = particles.compactMap { particle in
            var next = particle
            next.life -= dt
            next.radius += next.velocity * dt
            next.angle += next.angularVelocity * dt
            next.velocity *= max(0.86, 1 - dt * 0.12)
            return next.life > 0 ? next : nil
        }
    }

    private func waveformPalette() -> [WaveformRGBA] {
        let level = min(1.0, max(0.0, displayedColorLevel))
        let chillAmount = smoothstep(edge0: 0.02, edge1: 0.42, x: level)
        let grooveAmount = smoothstep(edge0: 0.38, edge1: 1.0, x: level)

        return zip(neutralPalette, chillPalette).enumerated().map { index, pair in
            let chilled = pair.0.mixed(with: pair.1, amount: chillAmount)
            return chilled.mixed(with: groovePalette[index], amount: grooveAmount)
        }
    }

    private func targetColorLevel(for state: HowTag) -> Double {
        switch state {
        case .groove:
            return 1.0
        case .chill:
            return 0.42
        case .neutral:
            return 0.0
        }
    }

    private func gradientColor(colors: [WaveformRGBA], progress: Double, alpha: Float) -> SIMD4<Float> {
        guard !colors.isEmpty else { return SIMD4<Float>(1, 1, 1, alpha) }

        let scaled = progress * Double(colors.count)
        let lowerIndex = Int(floor(scaled)) % colors.count
        let upperIndex = (lowerIndex + 1) % colors.count
        let amount = scaled - floor(scaled)
        return colors[lowerIndex].mixed(with: colors[upperIndex], amount: amount).vector(alpha: alpha)
    }

    private func particleHue(for state: HowTag) -> CGFloat {
        switch state {
        case .groove:
            return CGFloat.random(in: 0.00...0.13)
        case .chill:
            return CGFloat.random(in: 0.48...0.68)
        case .neutral:
            return CGFloat.random(in: 0.52...0.60)
        }
    }

    private func particleSaturation(for state: HowTag) -> CGFloat {
        switch state {
        case .groove:
            return CGFloat.random(in: 0.46...0.70)
        case .chill:
            return CGFloat.random(in: 0.30...0.54)
        case .neutral:
            return CGFloat.random(in: 0.10...0.24)
        }
    }

    private func normalizedPoint(_ point: CGPoint, size: CGSize) -> SIMD2<Float> {
        SIMD2<Float>(
            Float((point.x / size.width) * 2.0 - 1.0),
            Float(1.0 - (point.y / size.height) * 2.0)
        )
    }

    private func hsvToRGB(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: Float) -> SIMD4<Float> {
        let h = Double(hue.truncatingRemainder(dividingBy: 1))
        let s = Double(saturation)
        let v = Double(brightness)
        let sector = floor(h * 6)
        let fraction = h * 6 - sector
        let p = v * (1 - s)
        let q = v * (1 - fraction * s)
        let t = v * (1 - (1 - fraction) * s)

        let rgb: (Double, Double, Double)
        switch Int(sector) % 6 {
        case 0: rgb = (v, t, p)
        case 1: rgb = (q, v, p)
        case 2: rgb = (p, v, t)
        case 3: rgb = (p, q, v)
        case 4: rgb = (t, p, v)
        default: rgb = (v, p, q)
        }

        return SIMD4<Float>(Float(rgb.0), Float(rgb.1), Float(rgb.2), alpha)
    }

    private func makePipelineState(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat
    ) -> MTLRenderPipelineState? {
        guard let library = try? device.makeLibrary(source: Self.shaderSource, options: nil) else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "waveformVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "waveformFragment")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position;
        float4 color;
    };

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    vertex VertexOut waveformVertex(
        uint vertexID [[vertex_id]],
        const device VertexIn *vertices [[buffer(0)]]
    ) {
        VertexIn input = vertices[vertexID];
        VertexOut output;
        output.position = float4(input.position, 0.0, 1.0);
        output.color = input.color;
        return output;
    }

    fragment float4 waveformFragment(VertexOut input [[stage_in]]) {
        return input.color;
    }
    """
}
#endif
