import Foundation

/// Configuration for the SelfDB client
public struct SelfDBConfig {
    /// Base URL for the SelfDB API server
    public let baseUrl: String
    
    /// URL for the storage service (defaults to baseUrl with port 8001)
    public let storageUrl: String?
    
    /// Anonymous key for API access
    public let anonKey: String
    
    /// Additional headers to include with requests
    public let headers: [String: String]
    
    /// Request timeout in seconds
    public let timeout: TimeInterval
    
    public init(
        baseUrl: String,
        storageUrl: String? = nil,
        anonKey: String,
        headers: [String: String] = [:],
        timeout: TimeInterval = 10.0
    ) {
        self.baseUrl = baseUrl
        self.storageUrl = storageUrl ?? baseUrl.replacingOccurrences(of: ":8000", with: ":8001")
        self.anonKey = anonKey
        self.headers = headers
        self.timeout = timeout
    }
}