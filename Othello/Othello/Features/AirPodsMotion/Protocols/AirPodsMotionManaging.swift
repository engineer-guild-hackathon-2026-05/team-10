protocol AirPodsMotionManaging: AnyObject {
    var isDeviceMotionAvailable: Bool { get }
    var onEvent: ((AirPodsMotionEvent) -> Void)? { get set }
    var onSample: ((AirPodsMotionSample) -> Void)? { get set }
    var onStatusChange: ((AirPodsMotionStatus) -> Void)? { get set }

    func start(playbackPositionProvider: PlaybackPositionProviding)
    func stop()
}
