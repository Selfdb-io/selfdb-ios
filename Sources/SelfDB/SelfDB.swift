import Foundation

/// Main SelfDB client
public class SelfDB {
    /// Authentication client
    public let auth: AuthClient
    
    /// Database client
    public let database: DatabaseClient
    
    /// Storage client
    public let storage: StorageClient
    
    /// Initialize SelfDB client
    /// - Parameter config: SelfDB configuration
    public init(config: SelfDBConfig) {
        // Initialize global configuration
        Config.initialize(config)
        
        // Initialize clients
        self.auth = AuthClient()
        self.database = DatabaseClient(authClient: self.auth)
        self.storage = StorageClient(authClient: self.auth)
    }
}

/// Convenience function to create SelfDB client
/// - Parameter config: SelfDB configuration
/// - Returns: Configured SelfDB client
public func createClient(config: SelfDBConfig) -> SelfDB {
    return SelfDB(config: config)
}

/// Convenience function to create SelfDB client with string URLs
/// - Parameters:
///   - apiURL: Backend API URL string
///   - storageURL: Storage service URL string
///   - apiKey: Anonymous API key
/// - Returns: Configured SelfDB client or nil if URLs are invalid
public func createClient(apiURL: String, storageURL: String, apiKey: String) -> SelfDB? {
    guard let config = SelfDBConfig(apiURL: apiURL, storageURL: storageURL, apiKey: apiKey) else {
        return nil
    }
    return SelfDB(config: config)
}