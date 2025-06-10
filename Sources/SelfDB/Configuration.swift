import Foundation

/// Configuration for SelfDB client
public struct SelfDBConfig {
    /// The base URL for the SelfDB backend API
    public let apiURL: URL
    
    /// The base URL for the SelfDB storage service
    public let storageURL: URL
    
    /// Anonymous API key for public access
    public let apiKey: String
    
    /// Initialize SelfDB configuration
    /// - Parameters:
    ///   - apiURL: Base URL for the backend API (e.g., "https://api.selfdb.io/api/v1")
    ///   - storageURL: Base URL for the storage service (e.g., "https://storage.selfdb.io")
    ///   - apiKey: Anonymous API key for public access
    public init(apiURL: URL, storageURL: URL, apiKey: String) {
        self.apiURL = apiURL
        self.storageURL = storageURL
        self.apiKey = apiKey
    }
    
    /// Convenience initializer with string URLs
    /// - Parameters:
    ///   - apiURL: Base URL string for the backend API
    ///   - storageURL: Base URL string for the storage service
    ///   - apiKey: Anonymous API key for public access
    public init?(apiURL: String, storageURL: String, apiKey: String) {
        guard let apiURL = URL(string: apiURL),
              let storageURL = URL(string: storageURL) else {
            return nil
        }
        self.init(apiURL: apiURL, storageURL: storageURL, apiKey: apiKey)
    }
}

/// Global configuration manager
internal class Config {
    static var shared: SelfDBConfig?
    
    static func initialize(_ config: SelfDBConfig) {
        shared = config
    }
    
    static var current: SelfDBConfig {
        guard let config = shared else {
            fatalError("SelfDB configuration not initialized. Call SelfDB.initialize(config:) first.")
        }
        return config
    }
}