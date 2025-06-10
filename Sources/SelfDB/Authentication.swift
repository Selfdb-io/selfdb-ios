import Foundation

/// Authentication types and models
public struct LoginRequest: Codable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
   
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
      
    }
}

public struct AuthResponse: Codable {
    public let access_token: String
    public let refresh_token: String?
    public let token_type: String
    public let user_id: String?
    public let email: String?
    public let is_superuser: Bool?
    
    public init(access_token: String, refresh_token: String?, token_type: String, user_id: String?, email: String?, is_superuser: Bool?) {
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.token_type = token_type
        self.user_id = user_id
        self.email = email
        self.is_superuser = is_superuser
    }
}

public struct RefreshResponse: Codable {
    public let access_token: String
    public let token_type: String
    
    public init(access_token: String, token_type: String) {
        self.access_token = access_token
        self.token_type = token_type
    }
}

public struct RefreshTokenRequest: Codable {
    public let refresh_token: String
    
    public init(refreshToken: String) {
        self.refresh_token = refreshToken
    }
}

public struct User: Codable {
    public let id: String
    public let email: String
    public let is_active: Bool
    public let is_superuser: Bool?
    public let created_at: String
    public let updated_at: String?
    
    public init(id: String, email: String, is_active: Bool, is_superuser: Bool?, created_at: String, updated_at: String?) {
        self.id = id
        self.email = email
        self.is_active = is_active
        self.is_superuser = is_superuser
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

/// Authentication client for SelfDB
public class AuthClient {
    private let httpClient = HTTPClient()
    private var currentToken: String?
    private var currentRefreshToken: String?
    
    public init() {}
    
    /// Current access token
    public var accessToken: String? {
        return currentToken
    }
    
    /// Register a new user
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: User response
    @discardableResult
    public func register(email: String, password: String) async -> SelfDBResponse<User> {
        let request = RegisterRequest(email: email, password: password)
        
        do {
            let body = try JSONEncoder().encode(request)
            let response = await httpClient.request(
                endpoint: "/auth/register",
                method: .POST,
                body: body,
                responseType: User.self
            )
            
            // Registration doesn't return tokens, only user info
            return response
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Login with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Authentication response
    @discardableResult
    public func login(email: String, password: String) async -> SelfDBResponse<AuthResponse> {
        let loginData = "username=\(email)&password=\(password)"
        guard let body = loginData.data(using: .utf8) else {
            return SelfDBResponse(data: nil, error: .encodingError(NSError(domain: "EncodingError", code: 0)), statusCode: 0)
        }
        
        let headers = ["Content-Type": "application/x-www-form-urlencoded"]
        let response = await httpClient.request(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            headers: headers,
            responseType: AuthResponse.self
        )
        
        if let authData = response.data {
            currentToken = authData.access_token
            currentRefreshToken = authData.refresh_token
        }
        
        return response
    }
    
    /// Refresh access token
    /// - Returns: New refresh response
    @discardableResult
    public func refreshToken() async -> SelfDBResponse<RefreshResponse> {
        guard let refreshToken = currentRefreshToken else {
            return SelfDBResponse(data: nil, error: .authenticationRequired, statusCode: 0)
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        do {
            let body = try JSONEncoder().encode(request)
            let response = await httpClient.request(
                endpoint: "/auth/refresh",
                method: .POST,
                body: body,
                responseType: RefreshResponse.self
            )
            
            if let refreshData = response.data {
                currentToken = refreshData.access_token
            }
            
            return response
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Get current user information
    /// - Returns: User information
    public func getCurrentUser() async -> SelfDBResponse<User> {
        guard let token = currentToken else {
            return SelfDBResponse(data: nil, error: .authenticationRequired, statusCode: 0)
        }
        
        let headers = ["Authorization": "Bearer \(token)"]
        return await httpClient.request(
            endpoint: "/users/me",
            headers: headers,
            responseType: User.self
        )
    }
    
    /// Sign out current user
    public func signOut() {
        currentToken = nil
        currentRefreshToken = nil
    }
    
    /// Get authentication headers for API requests
    internal func getAuthHeaders() -> [String: String] {
        guard let token = currentToken else {
            return [:]
        }
        return ["Authorization": "Bearer \(token)"]
    }
}