import Foundation

/// User model
public struct User: Codable, Equatable {
    public let id: String
    public let email: String
    public let isActive: Bool
    public let isSuperuser: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case isActive = "is_active"
        case isSuperuser = "is_superuser"
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

/// Login response - matches backend TokenWithUserInfo response
public struct LoginResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let refreshToken: String
    public let isSuperuser: Bool
    public let email: String
    public let userId: String
    
    // Computed property for backward compatibility
    public var user: User {
        return User(
            id: userId,
            email: email,
            isActive: true, // We assume logged in users are active
            isSuperuser: isSuperuser,
            createdAt: Date(), // We don't have these from login response
            updatedAt: Date()
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case isSuperuser = "is_superuser"
        case email
        case userId = "user_id"
    }
}

/// Registration response
public struct RegisterResponse: Codable {
    public let user: User
    public let message: String?
}

/// Token refresh response - matches backend Token response (only returns access token)
public struct RefreshResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

/// Refresh token request structure
public struct RefreshTokenRequest: Codable {
    public let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}