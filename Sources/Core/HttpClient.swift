import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Configuration for retry behavior
public struct RetryConfig {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 10.0
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    public static let `default` = RetryConfig()
}

/// HTTP client with retry logic and error handling
public actor HttpClient {
    private let baseURL: String
    private let timeout: TimeInterval
    private let retryConfig: RetryConfig
    private let session: URLSession
    
    public init(
        baseURL: String,
        timeout: TimeInterval = 10.0,
        retryConfig: RetryConfig = .default
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryConfig = retryConfig
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    /// Calculate exponential backoff delay
    private func calculateDelay(attempt: Int) -> TimeInterval {
        let delay = retryConfig.baseDelay * pow(2.0, Double(attempt))
        return min(delay, retryConfig.maxDelay)
    }
    
    /// Handle URL response and convert to errors
    private func handleResponse(_ response: URLResponse?, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError("Invalid response received")
        }
        
        let statusCode = httpResponse.statusCode
        
        // Success range
        if 200...299 ~= statusCode {
            return
        }
        
        // Parse error message from response data
        var errorMessage = "Request failed with status \(statusCode)"
        var errorData: Any?
        
        if let data = data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    errorMessage = message
                    errorData = json
                }
            } catch {
                // If we can't parse JSON, use the raw data as string
                if let string = String(data: data, encoding: .utf8) {
                    errorMessage = string
                }
            }
        }
        
        // Throw appropriate error type
        switch statusCode {
        case 401:
            throw AuthError(errorMessage)
        case 400:
            throw ValidationError(errorMessage, data: errorData)
        default:
            throw ApiError(errorMessage, status: statusCode, data: errorData)
        }
    }
    
    /// Perform HTTP request with retry logic
    public func request<T: Codable>(
        method: HTTPMethod,
        path: String,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        let url = URL(string: baseURL + path)!
        
        for attempt in 0...retryConfig.maxRetries {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = method.rawValue
                request.httpBody = body
                
                // Always include anon-key header if available (required by backend)
                do {
                    let config = try Config.getInstance()
                    request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
                    
                    // Also include any additional configured headers
                    for (key, value) in config.headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                } catch {
                    // Config not available - this will likely cause auth failures
                }
                
                // Set provided headers (these can override defaults)
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                // Set content type for POST/PUT requests with body
                if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                
                // Debug logging for important requests
                if path.contains("register") || path.contains("initiate-upload") || path.contains("buckets") {
                    print("🌐 HTTP Request: \(method.rawValue) \(url)")
                    print("   - Headers: \(request.allHTTPHeaderFields ?? [:])")
                    if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                        print("   - Body: \(bodyString)")
                    }
                }
                
                let (data, response) = try await session.data(for: request)
                
                // Debug logging for responses
                if path.contains("register") || path.contains("initiate-upload") || path.contains("buckets") {
                    if let httpResponse = response as? HTTPURLResponse {
                        print("🌐 HTTP Response: \(httpResponse.statusCode)")
                        print("   - Content-Length: \(httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "none")")
                        print("   - Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "none")")
                        print("   - Data size: \(data.count) bytes")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("   - Response: \(responseString)")
                        }
                    }
                }
                
                try handleResponse(response, data: data)
                
                // Parse response data
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
                
                guard !data.isEmpty else {
                    print("❌ Empty response received for \(path)")
                    throw ApiError("Empty response received for \(path)", status: 200)
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
                
            } catch {
                // Don't retry on auth errors or validation errors
                if error is AuthError || error is ValidationError {
                    throw error
                }
                
                // Don't retry if we've exhausted attempts
                if attempt == retryConfig.maxRetries {
                    throw error
                }
                
                // Only retry on network errors, timeouts, or 5xx errors
                let shouldRetry: Bool
                if let apiError = error as? ApiError {
                    shouldRetry = apiError.status ?? 0 >= 500
                } else if error is NetworkError || error is TimeoutError {
                    shouldRetry = true
                } else if let urlError = error as? URLError {
                    shouldRetry = urlError.code == .timedOut || 
                                 urlError.code == .networkConnectionLost ||
                                 urlError.code == .notConnectedToInternet
                } else {
                    shouldRetry = false
                }
                
                if shouldRetry {
                    let delay = calculateDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
            }
        }
        
        throw NetworkError("Max retries exceeded")
    }
    
    /// Convenience method for GET requests
    public func get<T: Codable>(
        path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        return try await request(method: .GET, path: path, headers: headers)
    }
    
    /// Convenience method for POST requests
    public func post<T: Codable>(
        path: String,
        body: Codable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData: Data?
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            bodyData = try encoder.encode(body)
        } else {
            bodyData = nil
        }
        
        return try await request(method: .POST, path: path, headers: headers, body: bodyData)
    }
    
    /// Convenience method for PUT requests
    public func put<T: Codable>(
        path: String,
        body: Codable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData: Data?
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            bodyData = try encoder.encode(body)
        } else {
            bodyData = nil
        }
        
        return try await request(method: .PUT, path: path, headers: headers, body: bodyData)
    }
    
    /// Convenience method for DELETE requests
    public func delete<T: Codable>(
        path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        return try await request(method: .DELETE, path: path, headers: headers)
    }
}

/// HTTP methods
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// Empty response type for requests that don't return data
public struct EmptyResponse: Codable {
    public init() {}
}