import Foundation

/// Singleton configuration manager for SelfDB SDK
public final class Config {
    /// Shared singleton instance
    private static var instance: Config?
    
    /// The configuration object
    private let config: SelfDBConfig
    
    /// Private initializer to enforce singleton pattern
    private init(config: SelfDBConfig) {
        self.config = config
    }
    
    /// Initialize the configuration singleton
    /// - Parameter config: The SelfDB configuration
    /// - Returns: The configuration instance
    @discardableResult
    public static func initialize(config: SelfDBConfig) -> Config {
        let configInstance = Config(config: config)
        Config.instance = configInstance
        return configInstance
    }
    
    /// Get the singleton configuration instance
    /// - Throws: ConfigError if not initialized
    /// - Returns: The configuration instance
    public static func getInstance() throws -> Config {
        guard let instance = Config.instance else {
            throw SelfDBError(
                message: "SelfDB SDK not initialized. Call Config.initialize() first.",
                code: "CONFIG_NOT_INITIALIZED",
                suggestion: "Initialize the SDK with Config.initialize(config:) before using it"
            )
        }
        return instance
    }
    
    /// Base URL for the SelfDB API server
    public var baseUrl: String {
        return config.baseUrl
    }
    
    /// URL for the storage service
    public var storageUrl: String {
        return config.storageUrl ?? config.baseUrl.replacingOccurrences(of: ":8000", with: ":8001")
    }
    
    /// Anonymous key for API access
    public var anonKey: String {
        return config.anonKey
    }
    
    /// Additional headers to include with requests
    public var headers: [String: String] {
        return config.headers
    }
    
    /// Request timeout in seconds
    public var timeout: TimeInterval {
        return config.timeout
    }
}