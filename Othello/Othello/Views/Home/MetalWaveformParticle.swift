#if os(iOS)
import CoreGraphics

struct MetalWaveformParticle {
    var angle: CGFloat
    var radius: CGFloat
    var velocity: CGFloat
    var angularVelocity: CGFloat
    var size: CGFloat
    var life: CGFloat
    let maxLife: CGFloat
    var hue: CGFloat
    let saturation: CGFloat
    let twinklePhase: CGFloat

    init(
        angle: CGFloat,
        radius: CGFloat,
        velocity: CGFloat,
        angularVelocity: CGFloat,
        size: CGFloat,
        life: CGFloat,
        hue: CGFloat,
        saturation: CGFloat,
        twinklePhase: CGFloat
    ) {
        self.angle = angle
        self.radius = radius
        self.velocity = velocity
        self.angularVelocity = angularVelocity
        self.size = size
        self.life = life
        self.maxLife = life
        self.hue = hue
        self.saturation = saturation
        self.twinklePhase = twinklePhase
    }
}
#endif
