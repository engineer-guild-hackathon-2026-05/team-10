import SwiftUI
import Combine

enum ArtistCardSize {
    case large, medium
}

@MainActor
final class ForYouViewModel: ObservableObject {
    @Published var artists: [Artist] = Artist.mock
    @Published var searchQuery: String = ""

    var filteredArtists: [Artist] {
        searchQuery.isEmpty
            ? artists
            : artists.filter { $0.name.localizedStandardContains(searchQuery) }
    }

    func cardSize(at index: Int) -> ArtistCardSize {
        index % 3 == 0 ? .large : .medium
    }
}
