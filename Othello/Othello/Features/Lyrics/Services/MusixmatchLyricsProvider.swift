import Foundation

final class MusixmatchLyricsProvider: LyricsProviding {
    private let apiKey: String?
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        apiKey: String? = EnvironmentValueProvider.value(forKey: "MUSIXMATCH_API_KEY"),
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.musixmatch.com/ws/1.1/")!
    ) {
        self.apiKey = apiKey
        self.session = session
        self.baseURL = baseURL

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func fetchSynchronizedLyrics(for query: LyricsTrackQuery) async throws -> SynchronizedLyrics {
        guard let apiKey, !apiKey.isEmpty else {
            throw LyricsError.missingAPIKey
        }

        let track = try await matchedTrack(for: query, apiKey: apiKey)

        guard track.hasSubtitles else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        let subtitle = try await subtitle(forTrackID: track.trackId, apiKey: apiKey)
        let lines = LRCParser.parse(subtitle.subtitleBody)

        guard !lines.isEmpty else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        return SynchronizedLyrics(
            providerName: "Musixmatch",
            providerTrackID: String(track.trackId),
            query: query,
            lines: lines
        )
    }

    private func matchedTrack(
        for query: LyricsTrackQuery,
        apiKey: String
    ) async throws -> MusixmatchTrack {
        var queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "q_track", value: query.title),
            URLQueryItem(name: "q_artist", value: query.artistName),
            URLQueryItem(name: "f_has_subtitle", value: "1")
        ]

        if let albumName = query.albumName {
            queryItems.append(URLQueryItem(name: "q_album", value: albumName))
        }

        if let isrc = query.isrc {
            queryItems.append(URLQueryItem(name: "q_isrc", value: isrc))
        }

        let body: TrackMatchBody = try await request(
            endpoint: "matcher.track.get",
            queryItems: queryItems
        )

        guard let track = body.track else {
            throw LyricsError.trackNotFound
        }

        return track
    }

    private func subtitle(
        forTrackID trackID: Int,
        apiKey: String
    ) async throws -> MusixmatchSubtitle {
        let body: SubtitleBody = try await request(
            endpoint: "track.subtitle.get",
            queryItems: [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "track_id", value: String(trackID)),
                URLQueryItem(name: "subtitle_format", value: "lrc")
            ]
        )

        guard let subtitle = body.subtitle else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        return subtitle
    }

    private func request<Body: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) async throws -> Body {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint),
            resolvingAgainstBaseURL: false
        ) else {
            throw LyricsError.invalidRequest
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw LyricsError.invalidRequest
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw LyricsError.requestFailed(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw LyricsError.apiStatus(code: httpResponse.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }

        do {
            let apiResponse = try decoder.decode(MusixmatchResponse<Body>.self, from: data)

            guard apiResponse.message.header.statusCode == 200 else {
                throw LyricsError.apiStatus(
                    code: apiResponse.message.header.statusCode,
                    message: apiResponse.message.header.hint
                )
            }

            guard let body = apiResponse.message.body else {
                throw LyricsError.invalidResponse
            }

            return body
        } catch let error as LyricsError {
            throw error
        } catch {
            throw LyricsError.invalidResponse
        }
    }
}

private struct MusixmatchResponse<Body: Decodable>: Decodable {
    let message: Message

    struct Message: Decodable {
        let header: Header
        let body: Body?
    }

    struct Header: Decodable {
        let statusCode: Int
        let hint: String?
    }
}

private struct TrackMatchBody: Decodable {
    let track: MusixmatchTrack?
}

private struct SubtitleBody: Decodable {
    let subtitle: MusixmatchSubtitle?
}

private struct MusixmatchTrack: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let hasSubtitlesRaw: Int?

    var hasSubtitles: Bool {
        hasSubtitlesRaw == 1
    }

    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case artistName
        case hasSubtitlesRaw = "hasSubtitles"
    }
}

private struct MusixmatchSubtitle: Decodable {
    let subtitleBody: String
}
