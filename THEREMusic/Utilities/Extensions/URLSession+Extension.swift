import Foundation
import Combine

// MARK: - URLSession Extensions
extension URLSession {

    func dataTaskPublisher(for request: URLRequest, retries: Int) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .retry(retries)
            .eraseToAnyPublisher()
    }

    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppErrorType.networkUnavailable
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppErrorType.serverError(httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppErrorType.decodingFailed
        }
    }

    func fetch<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppErrorType.networkUnavailable
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { throw AppErrorType.unauthorized }
            if httpResponse.statusCode == 429 { throw AppErrorType.rateLimited }
            throw AppErrorType.serverError(httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppErrorType.decodingFailed
        }
    }
}

// MARK: - URL Builder
extension URL {
    init?(baseURL: String, path: String, queryItems: [URLQueryItem] = []) {
        var components = URLComponents(string: baseURL)
        components?.path += path
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { return nil }
        self = url
    }

    func appending(queryItems items: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var existing = components?.queryItems ?? []
        existing.append(contentsOf: items)
        components?.queryItems = existing
        return components?.url ?? self
    }
}
