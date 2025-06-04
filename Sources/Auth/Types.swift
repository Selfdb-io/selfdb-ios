import Foundation

/// User model
public struct User: Codable, Equatable {
    public let id: String
    public let email: String
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Authentication tokens
public struct AuthTokens: Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

/// Authentication state
public struct AuthState: Codable, Equatable {
    public let user: User?
    public let tokens: AuthTokens?
    public let isAuthenticated: Bool
    
    public init(user: User? = nil, tokens: AuthTokens? = nil, isAuthenticated: Bool = false) {
        self.user = user
        self.tokens = tokens
        self.isAuthenticated = isAuthenticated
    }
}

/// Login request
public struct LoginRequest: Codable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Registration request
public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Login response
public struct LoginResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: User
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token" 
        case user
    }
}

/// Registration response
public struct RegisterResponse: Codable {
    public let user: User
    public let message: String?
}

/// Token refresh response
public struct RefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}