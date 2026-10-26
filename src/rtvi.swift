import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
}


public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}


public class RTVIClient {

    private let api = "https://rtvi.com/_api"

    private var headers: [String: String]

    public init() {
        self.headers = [
            "Connection": "keep-alive",
            "Accept-Encoding": "deflate, zstd",
            "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        ]
    }

    private func fetchJSON(
        from urlString: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        queryParameters: [(String, String)]? = nil
    ) async throws -> Any {
        var urlComponents = URLComponents(string: urlString)
        if let queryParameters = queryParameters {
            urlComponents?.queryItems = queryParameters.map {
                URLQueryItem(name: $0.0, value: $0.1)
            }
        }
        guard let url = urlComponents?.url else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data)
    }

    private func filterParam(_ path: String, _ value: String) -> (String, String) {
        (path, value)
    }

    public func getHome() async throws -> Any {
        try await fetchJSON(from: "\(api)/home")
    }

    public func getSearchFilters() async throws -> Any {
        try await fetchJSON(from: "\(api)/search-page/filters")
    }

    public func getRubricFilters(slug: String) async throws -> Any {
        try await fetchJSON(from: "\(api)/rubrics/slug/\(slug)/filters")
    }

    ///   - sort: e.g. "date"
    ///   - indexes: e.g. "short"
    ///   - limit: page size
    ///   - offset: starting offset
    ///   - rubrics: array of rubric slugs
    ///   - geographies: array of geography slugs
    ///   - stories: array of story slugs
    ///   - tags: array of tag slugs
    ///   - authors: array of author slugs
    public func search(
        sort: String? = "date",
        indexes: String? = "short",
        limit: Int = 8,
        offset: Int = 0,
        rubrics: [String] = [],
        geographies: [String] = [],
        stories: [String] = [],
        tags: [String] = [],
        authors: [String] = []
    ) async throws -> Any {
        var params: [(String, String)] = []
        if let sort = sort { params.append(("sort", sort)) }
        if let indexes = indexes { params.append(("indexes", indexes)) }
        params.append(("limit", String(limit)))
        params.append(("offset", String(offset)))

        for (i, v) in rubrics.enumerated() {
            params.append(("filters[rubrics][$in][\(i)]", v))
        }
        for (i, v) in geographies.enumerated() {
            params.append(("filters[geographies][$in][\(i)]", v))
        }
        for (i, v) in stories.enumerated() {
            params.append(("filters[stories][$in][\(i)]", v))
        }
        for (i, v) in tags.enumerated() {
            params.append(("filters[tags][$in][\(i)]", v))
        }
        for (i, v) in authors.enumerated() {
            params.append(("filters[authors][$in][\(i)]", v))
        }

        return try await fetchJSON(from: "\(api)/search", queryParameters: params)
    }

    public func getArticles(
        rubricSlugs: [String] = [],
        geotagSlugs: [String] = [],
        storySlugs: [String] = [],
        tagSlugs: [String] = [],
        authorSlugs: [String] = [],
        sort: String = "date:desc",
        start: Int = 0,
        limit: Int = 9,
        fields: [String] = ["name", "slug", "date", "card_type", "icon"],
        populateImage: Bool = true,
        populateRubric: Bool = true
    ) async throws -> Any {
        var params: [(String, String)] = []

        for (i, v) in rubricSlugs.enumerated() {
            params.append(("filters[rubric][slug][$in][\(i)]", v))
        }
        for (i, v) in geotagSlugs.enumerated() {
            params.append(("filters[geotags][slug][$in][\(i)]", v))
        }
        for (i, v) in storySlugs.enumerated() {
            params.append(("filters[stories][slug][$in][\(i)]", v))
        }
        for (i, v) in tagSlugs.enumerated() {
            params.append(("filters[tags][slug][$in][\(i)]", v))
        }
        for (i, v) in authorSlugs.enumerated() {
            params.append(("filters[authors][slug][$in][\(i)]", v))
        }

        params.append(("sort", sort))
        params.append(("pagination[start]", String(start)))
        params.append(("pagination[limit]", String(limit)))

        for (i, f) in fields.enumerated() {
            params.append(("fields[\(i)]", f))
        }
        if populateImage {
            params.append(("populate[image][populate]", "file"))
        }
        if populateRubric {
            params.append(("populate[rubric]", "true"))
        }

        return try await fetchJSON(from: "\(api)/articles", queryParameters: params)
    }

    public func getArticle(slug: String) async throws -> Any {
        try await fetchJSON(from: "\(api)/articles/slug/\(slug)")
    }

    public func getRelatedArticles(slug: String, pageSize: Int = 4) async throws -> Any {
        try await fetchJSON(
            from: "\(api)/articles/slug/\(slug)/related",
            queryParameters: [("pagination[pageSize]", String(pageSize))]
        )
    }

    public func getRubric(slug: String) async throws -> Any {
        try await fetchJSON(from: "\(api)/rubrics/slug/\(slug)")
    }

    public func getOpinions(
        start: Int = 0,
        limit: Int = 12,
        fields: [String] = ["name", "slug", "date", "card_type"],
        populateRubric: Bool = true,
        populateAuthors: Bool = true
    ) async throws -> Any {
        var params: [(String, String)] = [
            ("sort", "date:desc"),
            ("pagination[start]", String(start)),
            ("pagination[limit]", String(limit))
        ]
        for (i, f) in fields.enumerated() {
            params.append(("fields[\(i)]", f))
        }
        if populateRubric {
            params.append(("populate[rubric]", "true"))
        }
        if populateAuthors {
            params.append(("populate[authors][populate][0]", "image"))
            params.append(("populate[authors][populate][1]", "contacts"))
        }
        return try await fetchJSON(from: "\(api)/opinions", queryParameters: params)
    }

    public func getVideos(
        start: Int = 0,
        limit: Int = 12,
        fields: [String] = ["name", "slug", "date", "duration"],
        populateImage: Bool = true,
        populateRubric: Bool = true,
        populateProgram: Bool = true
    ) async throws -> Any {
        var params: [(String, String)] = [
            ("sort", "date:desc"),
            ("pagination[start]", String(start)),
            ("pagination[limit]", String(limit))
        ]
        for (i, f) in fields.enumerated() {
            params.append(("fields[\(i)]", f))
        }
        if populateImage { params.append(("populate[image]", "true")) }
        if populateRubric { params.append(("populate[rubric]", "true")) }
        if populateProgram {
            params.append(("populate[program][fields][0]", "slug"))
        }
        return try await fetchJSON(from: "\(api)/videos", queryParameters: params)
    }

    public func getShorts(pageSize: Int = 7) async throws -> Any {
        try await fetchJSON(
            from: "\(api)/shorts",
            queryParameters: [
                ("sort", "date:desc"),
                ("pagination[pageSize]", String(pageSize))
            ]
        )
    }

    public func getMainProject(pageSize: Int = 1) async throws -> Any {
        try await fetchJSON(
            from: "\(api)/projects",
            queryParameters: [
                ("filters[main][$eq]", "true"),
                ("fields[0]", "name"),
                ("fields[1]", "slug"),
                ("fields[2]", "description"),
                ("fields[3]", "date"),
                ("fields[4]", "documentId"),
                ("fields[5]", "main_icon"),
                ("populate[image][populate][file]", "true"),
                ("sort", "date:desc"),
                ("pagination[pageSize]", String(pageSize))
            ]
        )
    }

    public func getTwits(start: Int = 0, limit: Int = 2) async throws -> Any {
        try await fetchJSON(
            from: "\(api)/twits",
            queryParameters: [
                ("sort", "sort:asc"),
                ("pagination[start]", String(start)),
                ("pagination[limit]", String(limit))
            ]
        )
    }

    public func getBroadcasts(regionSlug: String = "with_ads", pageSize: Int = 1) async throws -> Any {
        try await fetchJSON(
            from: "\(api)/broadcasts",
            queryParameters: [
                ("filters[region][slug][$eq]", regionSlug),
                ("pagination[pageSize]", String(pageSize))
            ]
        )
    }

    /// TV schedule. Dates must be `yyyy-MM-dd`.
    public func getSchedules(
        regionSlug: String = "with_ads",
        dateFrom: String,
        dateTo: String,
        page: Int = 1,
        pageSize: Int = 100,
        fields: [String] = ["date_from", "start_time", "date_to", "end_time", "program_name", "video_name"],
        populateProgram: Bool = true,
        populateVideo: Bool = true
    ) async throws -> Any {
        var params: [(String, String)] = [
            ("sort[0]", "date_from:asc"),
            ("sort[1]", "start_time:asc"),
            ("filters[region][slug][$eq]", regionSlug),
            ("filters[date_from][$gte]", dateFrom),
            ("filters[date_from][$lte]", dateTo),
            ("pagination[page]", String(page)),
            ("pagination[pageSize]", String(pageSize))
        ]
        for (i, f) in fields.enumerated() {
            params.append(("fields[\(i)]", f))
        }
        if populateProgram {
            params.append(("populate[program][fields][0]", "name"))
            params.append(("populate[program][fields][1]", "slug"))
            params.append(("populate[program][populate][image]", "true"))
        }
        if populateVideo {
            params.append(("populate[video][fields][0]", "name"))
            params.append(("populate[video][fields][1]", "slug"))
        }
        return try await fetchJSON(from: "\(api)/schedules", queryParameters: params)
    }
}
