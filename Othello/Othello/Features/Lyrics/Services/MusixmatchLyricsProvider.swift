import Foundation

final class MusixmatchLyricsProvider: LyricsProviding {
    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    private let apiKey: String?
    private let countryCode: String?
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        apiKey: String? = EnvironmentValueProvider.value(forKey: "MUSIXMATCH_API_KEY"),
        countryCode: String? = Locale.current.region?.identifier,
        session: URLSession = MusixmatchLyricsProvider.defaultSession,
        baseURL: URL = URL(string: "https://api.musixmatch.com/ws/1.1/")!
    ) {
        self.apiKey = apiKey
        self.countryCode = countryCode
        self.session = session
        self.baseURL = baseURL

        self.decoder = JSONDecoder()
    }

    func fetchSynchronizedLyrics(for query: LyricsTrackQuery) async throws -> SynchronizedLyrics {
        guard let apiKey, !apiKey.isEmpty else {
            throw LyricsError.missingAPIKey
        }

        debugLog("start lookup title=\(query.title) artist=\(query.artistName) musicKitID=\(query.musicKitID ?? "nil") isrc=\(query.isrc ?? "nil") duration=\(query.duration.map { String(Int($0.rounded())) } ?? "nil")")

        var failures: [String] = []

        if let lyrics = try await lyricsFromKnownIDs(for: query, apiKey: apiKey, failures: &failures) {
            return lyrics
        }

        if let lyrics = try await lyricsFromMatcherSubtitle(for: query, apiKey: apiKey, failures: &failures) {
            return lyrics
        }

        let track: MusixmatchTrack
        do {
            track = try await matchedTrack(for: query, apiKey: apiKey)
        } catch let error as LyricsError where isRecoverableLookupFailure(error) {
            failures.append("matcher.track.get: \(error.localizedDescription)")
            throw LyricsError.lookupFailed(failures)
        }

        if track.hasSubtitles, track.restricted != 1 {
            if let lyrics = try await lyricsFromMatchedTrack(track, query: query, apiKey: apiKey, failures: &failures) {
                return lyrics
            }
        } else if !track.hasSubtitles {
            failures.append("matcher.track.get: matched track has_subtitles=0")
        } else {
            failures.append("matcher.track.get: matched track is restricted")
        }

        if let lyrics = try await staticLyricsFromMatchedTrack(track, query: query, apiKey: apiKey, failures: &failures) {
            return lyrics
        }

        throw LyricsError.lookupFailed(failures)
    }

    private func lyricsFromKnownIDs(
        for query: LyricsTrackQuery,
        apiKey: String,
        failures: inout [String]
    ) async throws -> SynchronizedLyrics? {
        var attempts: [(label: String, providerTrackID: String, queryItems: [URLQueryItem])] = []

        if let musicKitID = query.musicKitID, !musicKitID.isEmpty {
            attempts.append((
                label: "track.subtitle.get track_itunes_id duration",
                providerTrackID: musicKitID,
                queryItems: subtitleQueryItems(
                    apiKey: apiKey,
                    query: query,
                    idItem: URLQueryItem(name: "track_itunes_id", value: musicKitID),
                    includeDuration: true
                )
            ))
            attempts.append((
                label: "track.subtitle.get track_itunes_id",
                providerTrackID: musicKitID,
                queryItems: subtitleQueryItems(
                    apiKey: apiKey,
                    query: query,
                    idItem: URLQueryItem(name: "track_itunes_id", value: musicKitID),
                    includeDuration: false
                )
            ))
        }

        if let isrc = query.isrc, !isrc.isEmpty {
            attempts.append((
                label: "track.subtitle.get track_isrc duration",
                providerTrackID: isrc,
                queryItems: subtitleQueryItems(
                    apiKey: apiKey,
                    query: query,
                    idItem: URLQueryItem(name: "track_isrc", value: isrc),
                    includeDuration: true
                )
            ))
            attempts.append((
                label: "track.subtitle.get track_isrc",
                providerTrackID: isrc,
                queryItems: subtitleQueryItems(
                    apiKey: apiKey,
                    query: query,
                    idItem: URLQueryItem(name: "track_isrc", value: isrc),
                    includeDuration: false
                )
            ))
        }

        for attempt in attempts {
            if let lyrics = try await lyricsFromAttempt(
                label: attempt.label,
                providerTrackID: attempt.providerTrackID,
                query: query,
                failures: &failures,
                fetchSubtitle: {
                    try await self.subtitle(queryItems: attempt.queryItems)
                }
            ) {
                return lyrics
            }
        }

        return nil
    }

    private func lyricsFromMatcherSubtitle(
        for query: LyricsTrackQuery,
        apiKey: String,
        failures: inout [String]
    ) async throws -> SynchronizedLyrics? {
        for includeDuration in [true, false] {
            if let lyrics = try await lyricsFromAttempt(
                label: includeDuration ? "matcher.subtitle.get duration" : "matcher.subtitle.get",
                providerTrackID: query.musicKitID ?? query.isrc,
                query: query,
                failures: &failures,
                fetchSubtitle: {
                    try await self.matcherSubtitle(
                        for: query,
                        apiKey: apiKey,
                        includeDuration: includeDuration
                    )
                }
            ) {
                return lyrics
            }
        }

        return nil
    }

    private func lyricsFromMatchedTrack(
        _ track: MusixmatchTrack,
        query: LyricsTrackQuery,
        apiKey: String,
        failures: inout [String]
    ) async throws -> SynchronizedLyrics? {
        let idItems = [
            URLQueryItem(name: "track_id", value: String(track.trackID)),
            track.commonTrackID.map { URLQueryItem(name: "commontrack_id", value: String($0)) },
            track.trackISRC.map { URLQueryItem(name: "track_isrc", value: $0) }
        ].compactMap { $0 }

        for idItem in idItems {
            if let lyrics = try await lyricsFromAttempt(
                label: "track.subtitle.get \(idItem.name) duration",
                providerTrackID: idItem.value ?? String(track.trackID),
                query: query,
                failures: &failures,
                fetchSubtitle: {
                    try await self.subtitle(queryItems: self.subtitleQueryItems(
                        apiKey: apiKey,
                        query: query,
                        idItem: idItem,
                        includeDuration: true
                    ))
                }
            ) {
                return lyrics
            }

            if let lyrics = try await lyricsFromAttempt(
                label: "track.subtitle.get \(idItem.name)",
                providerTrackID: idItem.value ?? String(track.trackID),
                query: query,
                failures: &failures,
                fetchSubtitle: {
                    try await self.subtitle(queryItems: self.subtitleQueryItems(
                        apiKey: apiKey,
                        query: query,
                        idItem: idItem,
                        includeDuration: false
                    ))
                }
            ) {
                return lyrics
            }
        }

        return nil
    }

    private func staticLyricsFromMatchedTrack(
        _ track: MusixmatchTrack,
        query: LyricsTrackQuery,
        apiKey: String,
        failures: inout [String]
    ) async throws -> SynchronizedLyrics? {
        let idItems = [
            URLQueryItem(name: "track_id", value: String(track.trackID)),
            track.commonTrackID.map { URLQueryItem(name: "commontrack_id", value: String($0)) },
            track.trackISRC.map { URLQueryItem(name: "track_isrc", value: $0) }
        ].compactMap { $0 }

        for idItem in idItems {
            do {
                let lyrics = try await trackLyrics(queryItems: lyricsQueryItems(apiKey: apiKey, idItem: idItem))
                let parsedLyrics = try staticLyrics(
                    from: lyrics,
                    providerTrackID: idItem.value ?? String(track.trackID),
                    query: query
                )
                debugLog("track.lyrics.get \(idItem.name): success lines=\(parsedLyrics.lines.count)")
                return parsedLyrics
            } catch let error as LyricsError where isRecoverableLookupFailure(error) {
                let message = "track.lyrics.get \(idItem.name): \(error.localizedDescription)"
                debugLog(message)
                failures.append(message)
            }
        }

        return nil
    }

    private func lyricsFromAttempt(
        label: String,
        providerTrackID: String?,
        query: LyricsTrackQuery,
        failures: inout [String],
        fetchSubtitle: () async throws -> MusixmatchSubtitle
    ) async throws -> SynchronizedLyrics? {
        do {
            let subtitle = try await fetchSubtitle()
            let lyrics = try lyrics(from: subtitle, providerTrackID: providerTrackID, query: query)
            debugLog("\(label): success lines=\(lyrics.lines.count)")
            return lyrics
        } catch let error as LyricsError where isRecoverableLookupFailure(error) {
            let message = "\(label): \(error.localizedDescription)"
            debugLog(message)
            failures.append(message)
            return nil
        }
    }

    private func matchedTrack(
        for query: LyricsTrackQuery,
        apiKey: String
    ) async throws -> MusixmatchTrack {
        var queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "q_track", value: query.title),
            URLQueryItem(name: "q_artist", value: query.artistName),
            URLQueryItem(name: "f_has_subtitle", value: "1")
        ]

        if let countryCode {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }

        if let albumName = query.albumName {
            queryItems.append(URLQueryItem(name: "q_album", value: albumName))
        }

        if let isrc = query.isrc {
            queryItems.append(URLQueryItem(name: "track_isrc", value: isrc))
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

    private func subtitle(queryItems: [URLQueryItem]) async throws -> MusixmatchSubtitle {
        let body: SubtitleBody = try await request(endpoint: "track.subtitle.get", queryItems: queryItems)

        guard let subtitle = body.subtitle else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        return subtitle
    }

    private func trackLyrics(queryItems: [URLQueryItem]) async throws -> MusixmatchLyrics {
        let body: LyricsBody = try await request(endpoint: "track.lyrics.get", queryItems: queryItems)

        guard let lyrics = body.lyrics else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        return lyrics
    }

    private func matcherSubtitle(
        for query: LyricsTrackQuery,
        apiKey: String,
        includeDuration: Bool
    ) async throws -> MusixmatchSubtitle {
        var queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "q_track", value: query.title),
            URLQueryItem(name: "q_artist", value: query.artistName),
            URLQueryItem(name: "subtitle_format", value: "lrc")
        ]

        queryItems.append(contentsOf: durationQueryItems(for: query, includeDuration: includeDuration))

        if let isrc = query.isrc {
            queryItems.append(URLQueryItem(name: "track_isrc", value: isrc))
        }

        if let countryCode {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }

        let body: SubtitleBody = try await request(endpoint: "matcher.subtitle.get", queryItems: queryItems)

        guard let subtitle = body.subtitle else {
            throw LyricsError.synchronizedLyricsUnavailable
        }

        return subtitle
    }

    private func subtitleQueryItems(
        apiKey: String,
        query: LyricsTrackQuery,
        idItem: URLQueryItem,
        includeDuration: Bool
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "apikey", value: apiKey),
            idItem,
            URLQueryItem(name: "subtitle_format", value: "lrc")
        ]

        queryItems.append(contentsOf: durationQueryItems(for: query, includeDuration: includeDuration))

        if let countryCode {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }

        return queryItems
    }

    private func lyricsQueryItems(apiKey: String, idItem: URLQueryItem) -> [URLQueryItem] {
        [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "apikey", value: apiKey),
            idItem
        ]
    }

    private func durationQueryItems(
        for query: LyricsTrackQuery,
        includeDuration: Bool
    ) -> [URLQueryItem] {
        guard includeDuration, let duration = query.duration else {
            return []
        }

        return [
            URLQueryItem(name: "f_subtitle_length", value: String(Int(duration.rounded()))),
            URLQueryItem(name: "f_subtitle_length_max_deviation", value: "2")
        ]
    }

    private func lyrics(
        from subtitle: MusixmatchSubtitle,
        providerTrackID: String?,
        query: LyricsTrackQuery
    ) throws -> SynchronizedLyrics {
        guard subtitle.restricted != 1 else {
            throw LyricsError.restrictedLyrics
        }

        let subtitleBody = subtitle.subtitleBody ?? ""
        let lines = LRCParser.parse(subtitleBody)

        guard !lines.isEmpty else {
            throw subtitleBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? LyricsError.emptySubtitleBody
                : LyricsError.synchronizedLyricsUnavailable
        }

        return SynchronizedLyrics(
            providerName: "Musixmatch",
            providerTrackID: providerTrackID,
            query: query,
            lines: lines
        )
    }

    private func staticLyrics(
        from lyrics: MusixmatchLyrics,
        providerTrackID: String?,
        query: LyricsTrackQuery
    ) throws -> SynchronizedLyrics {
        guard lyrics.restricted != 1 else {
            throw LyricsError.restrictedLyrics
        }

        let lyricsBody = lyrics.lyricsBody ?? ""
        let lines = StaticLyricsParser.parse(lyricsBody)

        guard !lines.isEmpty else {
            throw lyricsBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? LyricsError.emptySubtitleBody
                : LyricsError.synchronizedLyricsUnavailable
        }

        return SynchronizedLyrics(
            providerName: "Musixmatch (静的歌詞)",
            providerTrackID: providerTrackID,
            query: query,
            lines: lines,
            isTimeSynced: false
        )
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

        debugLog("request \(endpoint) \(sanitizedQuery(queryItems))")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            debugLog("request failed \(endpoint) error=\(error.localizedDescription)")
            throw LyricsError.requestFailed(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse {
            debugLog("http \(endpoint) status=\(httpResponse.statusCode) bytes=\(data.count)")
        }

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw LyricsError.apiStatus(code: httpResponse.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }

        do {
            let apiResponse = try decoder.decode(MusixmatchResponse<Body>.self, from: data)
            debugLog("response \(endpoint) status=\(apiResponse.message.header.statusCode) hint=\(apiResponse.message.header.hint ?? "nil")")

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
            debugLog("decode failed \(endpoint) error=\(error.localizedDescription)")
            throw LyricsError.invalidResponse
        }
    }

    private func isRecoverableLookupFailure(_ error: LyricsError) -> Bool {
        switch error {
        case .trackNotFound, .restrictedLyrics, .emptySubtitleBody, .synchronizedLyricsUnavailable, .lookupFailed:
            return true
        case .apiStatus(let code, _):
            return code == 400 || code == 403 || code == 404
        case .missingAPIKey, .invalidRequest, .invalidResponse, .requestFailed:
            return false
        }
    }

    private func sanitizedQuery(_ queryItems: [URLQueryItem]) -> String {
        queryItems
            .map { item in
                let value = item.name == "apikey" ? "<redacted>" : (item.value ?? "")
                return "\(item.name)=\(value)"
            }
            .joined(separator: "&")
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MusixmatchLyricsProvider] \(message)")
        #endif
    }
}

private struct MusixmatchResponse<Body: Decodable>: Decodable {
    let message: Message

    struct Message: Decodable {
        let header: Header
        let body: Body?

        enum CodingKeys: String, CodingKey {
            case header
            case body
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            header = try container.decode(Header.self, forKey: .header)
            body = try? container.decode(Body.self, forKey: .body)
        }
    }

    struct Header: Decodable {
        let statusCode: Int
        let hint: String?

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case hint
        }
    }
}

private struct TrackMatchBody: Decodable {
    let track: MusixmatchTrack?
}

private struct SubtitleBody: Decodable {
    let subtitle: MusixmatchSubtitle?
}

private struct LyricsBody: Decodable {
    let lyrics: MusixmatchLyrics?
}

private struct MusixmatchTrack: Decodable {
    let trackID: Int
    let commonTrackID: Int?
    let trackName: String
    let artistName: String
    let trackISRC: String?
    let hasSubtitles: Bool
    let restricted: Int?

    private let hasSubtitlesRaw: Int?

    enum CodingKeys: String, CodingKey {
        case trackID = "track_id"
        case commonTrackID = "commontrack_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case trackISRC = "track_isrc"
        case hasSubtitlesRaw = "has_subtitles"
        case restricted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackID = try container.decode(Int.self, forKey: .trackID)
        commonTrackID = try container.decodeIfPresent(Int.self, forKey: .commonTrackID)
        trackName = try container.decode(String.self, forKey: .trackName)
        artistName = try container.decode(String.self, forKey: .artistName)
        trackISRC = try container.decodeIfPresent(String.self, forKey: .trackISRC)
        hasSubtitlesRaw = try container.decodeIfPresent(Int.self, forKey: .hasSubtitlesRaw)
        hasSubtitles = hasSubtitlesRaw == 1
        restricted = try container.decodeIfPresent(Int.self, forKey: .restricted)
    }
}

private struct MusixmatchSubtitle: Decodable {
    let subtitleBody: String?
    let restricted: Int?

    enum CodingKeys: String, CodingKey {
        case subtitleBody = "subtitle_body"
        case restricted
    }
}

private struct MusixmatchLyrics: Decodable {
    let lyricsBody: String?
    let restricted: Int?

    enum CodingKeys: String, CodingKey {
        case lyricsBody = "lyrics_body"
        case restricted
    }
}
