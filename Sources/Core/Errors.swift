import Foundation

/// Configuration for SelfDB error creation
public struct ErrorConfig {
    public let message: String
    public let code: String?
    public let action: String?
    public let suggestion: String?
    public let retryable: Bool
    public let status: Int?
    public let data: Any?
    
    public init(
        message: String,
        code: String? = nil,
        action: String? = nil,
        suggestion: String? = nil,
        retryable: Bool = false,
        status: Int? = nil,
        data: Any? = nil
    ) {
        self.message = message
        self.code = code
        self.action = action
        self.suggestion = suggestion
        self.retryable = retryable
        self.status = status
        self.data = data
    }
}

/// Base error class for all SelfDB SDK errors
public class SelfDBError: Error, LocalizedError {
    public let code: String
    public let action: String?
    public let suggestion: String?
    public let retryable: Bool
    public let status: Int?
    public let data: Any?
    
    private let _message: String
    
    public var errorDescription: String? {
        return _message
    }
    
    public convenience init(
        _ message: String,
        status: Int? = nil,
        data: Any? = nil
    ) {
        self.init(
            message: message,
            code: "GENERIC_ERROR",
            retryable: false,
            status: status,
            data: data
        )
    }
    
    public init(
        message: String,
        code: String = "GENERIC_ERROR",
        action: String? = nil,
        suggestion: String? = nil,
        retryable: Bool = false,
        status: Int? = nil,
        data: Any? = nil
    ) {
        self._message = message
        self.code = code
        self.action = action
        self.suggestion = suggestion
        self.retryable = retryable
        self.status = status
        self.data = data
    }
    
    public convenience init(config: ErrorConfig) {
        self.init(
            message: config.message,
            code: config.code ?? "GENERIC_ERROR",
            action: config.action,
            suggestion: config.suggestion,
            retryable: config.retryable,
            status: config.status,
            data: config.data
        )
    }
    
    /// Check if this error is retryable
    public func isRetryable() -> Bool {
        return retryable
    }
}

/// API-related errors
public class ApiError: SelfDBError {
    public convenience init(
        _ message: String,
        status: Int,
        data: Any? = nil
    ) {
        self.init(
            message: message,
            code: "API_ERROR",
            retryable: status >= 500,
            status: status,
            data: data
        )
    }
}

/// Network connectivity errors
public class NetworkError: SelfDBError {
    public convenience init(_ message: String) {
        self.init(
            message: message,
            code: "NETWORK_ERROR",
            suggestion: "Check your internet connection and SelfDB server status",
            retryable: true
        )
    }
}

/// Request timeout errors
public class TimeoutError: SelfDBError {
    public convenience init(_ message: String) {
        self.init(
            message: message,
            code: "TIMEOUT_ERROR",
            suggestion: "The request took too long. Try again or check your connection",
            retryable: true
        )
    }
}

/// Authentication-related errors
public class AuthError: SelfDBError {
    public convenience init(_ message: String) {
        self.init(
            message: message,
            code: "AUTH_ERROR",
            action: "auth.login",
            suggestion: "Check your credentials or login again",
            status: 401
        )
    }
}

/// Input validation errors
public class ValidationError: SelfDBError {
    public convenience init(_ message: String, data: Any? = nil) {
        self.init(
            message: message,
            code: "VALIDATION_ERROR",
            suggestion: "Check your input data and try again",
            status: 400,
            data: data
        )
    }
}