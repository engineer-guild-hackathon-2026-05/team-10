import Combine
import Foundation

@MainActor
final class ReactionTimelineViewModel: ObservableObject {
    @Published var events: [ReactionEvent]
    @Published var selectedEvent: ReactionEvent?
    @Published var showDialogueSheet: Bool = false

    let trackTitle: String
    let trackArtist: String
    let duration: TimeInterval

    init(trackTitle: String, trackArtist: String, duration: TimeInterval, events: [ReactionEvent] = []) {
        self.trackTitle = trackTitle
        self.trackArtist = trackArtist
        self.duration = duration
        self.events = events
    }

    func selectEvent(_ event: ReactionEvent) {
        selectedEvent = event
        showDialogueSheet = true
    }
}
