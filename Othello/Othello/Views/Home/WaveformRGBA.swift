#if os(iOS)
struct WaveformRGBA {
    let red: Double
    let green: Double
    let blue: Double

    func vector(alpha: Float) -> SIMD4<Float> {
        SIMD4<Float>(Float(red), Float(green), Float(blue), alpha)
    }

    func mixed(with other: WaveformRGBA, amount: Double) -> WaveformRGBA {
        let t = min(1.0, max(0.0, amount))
        return WaveformRGBA(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t
        )
    }
}

let neutralPalette: [WaveformRGBA] = [
    WaveformRGBA(red: 0.70, green: 0.74, blue: 0.76),
    WaveformRGBA(red: 0.48, green: 0.54, blue: 0.58),
    WaveformRGBA(red: 0.78, green: 0.80, blue: 0.76),
    WaveformRGBA(red: 0.38, green: 0.44, blue: 0.48)
]

let chillPalette: [WaveformRGBA] = [
    WaveformRGBA(red: 0.16, green: 0.68, blue: 1.0),
    WaveformRGBA(red: 0.28, green: 0.88, blue: 0.76),
    WaveformRGBA(red: 0.46, green: 0.62, blue: 1.0),
    WaveformRGBA(red: 0.70, green: 0.54, blue: 1.0)
]

let groovePalette: [WaveformRGBA] = [
    WaveformRGBA(red: 1.0, green: 0.18, blue: 0.22),
    WaveformRGBA(red: 1.0, green: 0.58, blue: 0.12),
    WaveformRGBA(red: 0.28, green: 0.86, blue: 0.72),
    WaveformRGBA(red: 0.95, green: 0.28, blue: 0.78)
]

func smoothstep(edge0: Double, edge1: Double, x: Double) -> Double {
    let t = min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)
}
#endif
