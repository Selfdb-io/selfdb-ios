import Foundation
import Core

/// Authentication client for SelfDB
public final class AuthClient {
    private let httpClient: HttpClient
    private let keychain: KeychainHelper
    private var authState: AuthState = AuthState()
    
    // Keychain keys
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userKey = "selfdb_user"
    
    public init() async throws {
        let config = try Config.getInstance()
        self.httpClient = HttpClient(baseURL: config.baseUrl, timeout: config.timeout)
        self.keychain = KeychainHelper()
        await loadAuthState()
    }
    
    /// Load authentication state from keychain
    private func loadAuthState() async {
        do {
            guard let accessToken = try keychain.retrieve(key: accessTokenKey),
                  let refreshToken = try keychain.retrieve(key: refreshTokenKey),
                  let userJson = try keychain.retrieve(key: userKey),
                  let userData = userJson.data(using: .utf8) else {
                clearAuthState()
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let user = try decoder.decode(User.self, from: userData)
            let tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
            
            self.authState = AuthState(user: user, tokens: tokens, isAuthenticated: true)
        } catch {
            clearAuthState()
        }
    }
    
    /// Save authentication state to keychain
    private func saveAuthState() {
        guard let tokens = authState.tokens,
              let user = authState.user else {
            return
        }
        
        do {
            try keychain.store(key: accessTokenKey, value: tokens.accessToken)
            try keychain.store(key: refreshTokenKey, value: tokens.refreshToken)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let userData = try encoder.encode(user)
            if let userJson = String(data: userData, encoding: .utf8) {
                try keychain.store(key: userKey, value: userJson)
            }
        } catch {
            // Silently fail - auth will still work for this session
        }
    }
    
    /// Clear authentication state
    private func clearAuthState() {
        self.authState = AuthState()
        try? keychain.delete(key: accessTokenKey)
        try? keychain.delete(key: refreshTokenKey)
        try? keychain.delete(key: userKey)
    }
    
    /// Get authentication headers for API requests
    public func getAuthHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        
        // Always include apikey if available (required for storage service)
        do {
            let config = try Config.getInstance()
            headers["apikey"] = config.anonKey
        } catch {
            // Config not available
        }
        
        // Include Authorization header if authenticated
        if authState.isAuthenticated, let tokens = authState.tokens {
            headers["Authorization"] = "Bearer \(tokens.accessToken)"
        }
        
        return headers
    }
    
    /// Login with email and password
    /// - Parameter credentials: Login credentials
    /// - Returns: Login response with user and tokens
    /// - Throws: AuthError or other SelfDB errors
    public func login(credentials: LoginRequest) async throws -> LoginResponse {
        // Backend expects OAuth2PasswordRequestForm with username/password
        let formData = [
            "username": credentials.email, // OAuth2 uses 'username' field for email
            "password": credentials.password
        ]
        
        // Send as form data (application/x-www-form-urlencoded)
        let formBody = formData.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let bodyData = formBody.data(using: .utf8)!
        
        let response: LoginResponse = try await httpClient.request(
            method: .POST,
            path: "/api/v1/auth/login",
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: bodyData
        )
        
        let tokens = AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        self.authState = AuthState(
            user: response.user,
            tokens: tokens,
            isAuthenticated: true
        )
        
        saveAuthState()
        
        return response
    }
    
    /// Register a new user
    /// - Parameter credentials: Registration credentials
    /// - Returns: User (registration doesn't automatically log in)
    /// - Throws: ValidationError or other SelfDB errors
    public func register(credentials: RegisterRequest) async throws -> User {
        // Include API key in headers for register request
        var headers: [String: String] = [:]
        headers["apikey"] = config.anonKey
        
        let user: User = try await httpClient.request(
            method: .POST,
            path: "/api/v1/auth/register",
            headers: headers,
            body: credentials
        )
        
        // Note: Registration doesn't automatically log in the user
        // The caller needs to call login() separately if they want to authenticate
        return user
    }
    
    /// Logout the current user
    /// - Throws: SelfDB errors
    public func logout() async throws {
        if authState.isAuthenticated {
            do {
                let _: EmptyResponse = try await httpClient.post(
                    path: "/api/v1/auth/logout",
                    headers: getAuthHeaders()
                )
            } catch {
                // Even if logout fails on server, clear local state
            }
        }
        
        clearAuthState()
    }
    
    /// Refresh authentication tokens
    /// - Returns: New tokens
    /// - Throws: AuthError if refresh fails
    public func refresh() async throws -> AuthTokens {
        guard let currentTokens = authState.tokens else {
            throw AuthError("No refresh token available")
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: currentTokens.refreshToken)
        let response: RefreshResponse = try await httpClient.post(
            path: "/api/v1/auth/refresh",
            body: refreshRequest
        )
        
        // Backend only returns new access token, keep existing refresh token
        let newTokens = AuthTokens(
            accessToken: response.accessToken,
            refreshToken: currentTokens.refreshToken // Keep existing refresh token
        )
        
        // Update auth state with new tokens
        self.authState = AuthState(
            user: authState.user,
            tokens: newTokens,
            isAuthenticated: true
        )
        
        saveAuthState()
        
        return newTokens
    }
    
    /// Get current user information from server
    /// - Returns: Current user, or nil if not authenticated
    /// - Throws: AuthError or other SelfDB errors
    public func getUser() async throws -> User? {
        guard authState.isAuthenticated else {
            return nil
        }
        
        do {
            let user: User = try await httpClient.get(
                path: "/api/v1/users/me",
                headers: getAuthHeaders()
            )
            
            // Update auth state with fresh user data
            self.authState = AuthState(
                user: user,
                tokens: authState.tokens,
                isAuthenticated: true
            )
            
            saveAuthState()
            
            return user
        } catch {
            if error is AuthError {
                clearAuthState()
            }
            throw error
        }
    }
    
    /// Get current user from local state (no network call)
    /// - Returns: Current user, or nil if not authenticated
    public func getCurrentUser() -> User? {
        return authState.user
    }
    
    /// Check if user is authenticated
    /// - Returns: True if authenticated
    public func isAuthenticated() -> Bool {
        return authState.isAuthenticated
    }
    
    /// Get current authentication tokens
    /// - Returns: Current tokens, or nil if not authenticated
    public func getTokens() -> AuthTokens? {
        return authState.tokens
    }
    
    /// Make an authenticated HTTP request
    /// - Parameters:
    ///   - method: HTTP method
    ///   - path: API path
    ///   - body: Request body (will be JSON encoded)
    ///   - additionalHeaders: Additional headers
    /// - Returns: Decoded response
    /// - Throws: SelfDB errors
    public func makeAuthenticatedRequest<T: Codable>(
        method: HTTPMethod,
        path: String,
        body: Codable? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var headers = getAuthHeaders()
        
        // Merge additional headers
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        
        do {
            return try await httpClient.request(
                method: method,
                path: path,
                headers: headers,
                body: body != nil ? try JSONEncoder().encode(body!) : nil
            )
        } catch {
            // If we get an auth error and have a refresh token, try to refresh
            if error is AuthError,
               authState.tokens?.refreshToken != nil {
                do {
                    _ = try await refresh()
                    
                    // Update headers with new token
                    headers = getAuthHeaders()
                    for (key, value) in additionalHeaders {
                        headers[key] = value
                    }
                    
                    // Retry the request
                    return try await httpClient.request(
                        method: method,
                        path: path,
                        headers: headers,
                        body: body != nil ? try JSONEncoder().encode(body!) : nil
                    )
                } catch {
                    // Refresh failed, clear auth state
                    clearAuthState()
                    throw error
                }
            }
            
            throw error
        }
    }
}