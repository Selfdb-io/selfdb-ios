import Foundation
import Core
import Auth
import Database
import Storage
import Realtime

/// Main SelfDB client providing access to all services
public final class SelfDB {
    /// Authentication client
    public let auth: AuthClient
    
    /// Database client for CRUD operations
    public let db: DatabaseClient
    
    /// Storage client for file and bucket operations
    public let storage: StorageClient
    
    /// Realtime client for WebSocket connections
    public let realtime: RealtimeClient
    
    /// Initialize SelfDB client
    /// - Parameters:
    ///   - config: SelfDB configuration
    ///   - realtimeConfig: Optional realtime configuration
    /// - Throws: Configuration or initialization errors
    public init(config: SelfDBConfig, realtimeConfig: RealtimeConfig? = nil) async throws {
        // Initialize the configuration singleton
        Config.initialize(config: config)
        
        // Initialize auth client
        self.auth = try await AuthClient()
        
        // Initialize other clients
        self.db = DatabaseClient(authClient: auth)
        self.storage = try StorageClient(authClient: auth)
        self.realtime = try RealtimeClient(authClient: auth, config: realtimeConfig ?? RealtimeConfig())
    }
}

/// Convenience function to create a SelfDB client
/// - Parameters:
///   - config: SelfDB configuration
///   - realtimeConfig: Optional realtime configuration
/// - Returns: Initialized SelfDB client
/// - Throws: Configuration or initialization errors
public func createClient(config: SelfDBConfig, realtimeConfig: RealtimeConfig? = nil) async throws -> SelfDB {
    return try await SelfDB(config: config, realtimeConfig: realtimeConfig)
}
