import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// SelfDB specific errors
public enum SelfDBError: LocalizedError {
    case configurationNotInitialized
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case authenticationRequired
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .configurationNotInitialized:
            return "SelfDB configuration not initialized"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

/// Result wrapper for API responses
public struct SelfDBResponse<T: Codable> {
    public let data: T?
    public let error: SelfDBError?
    public let statusCode: Int
    
    public var isSuccess: Bool {
        return error == nil && statusCode >= 200 && statusCode < 300
    }
    
    public init(data: T?, error: SelfDBError?, statusCode: Int) {
        self.data = data
        self.error = error
        self.statusCode = statusCode
    }
}

/// HTTP client for SelfDB API requests
internal class HTTPClient {
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    /// Perform HTTP request
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async -> SelfDBResponse<T> {
        do {
            guard let url = URL(string: Config.current.apiURL.absoluteString + endpoint) else {
                print("❌ [HTTPClient] Invalid URL: \(endpoint)")
                return SelfDBResponse(data: nil, error: .invalidURL, statusCode: 0)
            }

            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpBody = body
            
            // Set default headers
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Config.current.apiKey, forHTTPHeaderField: "apikey")
            
            // Add custom headers
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // ➡️  Log outgoing request
            #if DEBUG
            print("➡️ [HTTPClient] \(method.rawValue) \(url.absoluteString)")
            #endif

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [HTTPClient] Invalid response for \(endpoint)")
                return SelfDBResponse(data: nil, error: .invalidResponse, statusCode: 0)
            }

            let statusCode = httpResponse.statusCode
            #if DEBUG
            print("⬅️ [HTTPClient] \(statusCode) \(endpoint)")
            #endif
            
            if statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8)
                return SelfDBResponse(data: nil, error: .httpError(statusCode: statusCode, message: errorMessage), statusCode: statusCode)
            }
            
            if statusCode == 204 { // No content
                return SelfDBResponse(data: nil, error: nil, statusCode: statusCode)
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return SelfDBResponse(data: decodedData, error: nil, statusCode: statusCode)
            } catch {
                return SelfDBResponse(data: nil, error: .decodingError(error), statusCode: statusCode)
            }
            
        } catch {
            #if DEBUG
            print("❌ [HTTPClient] Network error for \(endpoint): \(error.localizedDescription)")
            #endif
            return SelfDBResponse(data: nil, error: .networkError(error), statusCode: 0)
        }
    }
    
    /// Perform HTTP request without expecting a response body
    func request(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async -> SelfDBResponse<EmptyResponse> {
        return await request(endpoint: endpoint, method: method, body: body, headers: headers, responseType: EmptyResponse.self)
    }
}

/// HTTP methods
internal enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// Empty response for requests that don't return data
public struct EmptyResponse: Codable {
}