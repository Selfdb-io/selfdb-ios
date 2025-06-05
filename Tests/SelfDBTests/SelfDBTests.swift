import XCTest
@testable import SelfDB
@testable import Core
@testable import Auth
@testable import Database
@testable import Storage

final class SelfDBTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testSelfDBConfigCreation() throws {
        let config = SelfDBConfig(
            baseUrl: "http://localhost:8000",
            anonKey: "test-key"
        )
        
        XCTAssertEqual(config.baseUrl, "http://localhost:8000")
        XCTAssertEqual(config.anonKey, "test-key")
        XCTAssertEqual(config.storageUrl, "http://localhost:8001") // Should auto-replace port
        XCTAssertEqual(config.timeout, 10.0) // Default timeout
    }
    
    func testConfigSingleton() throws {
        let config = SelfDBConfig(
            baseUrl: "http://localhost:8000",
            anonKey: "test-key"
        )
        
        let configInstance = Config.initialize(config: config)
        let retrievedInstance = try Config.getInstance()
        
        XCTAssertEqual(configInstance.baseUrl, retrievedInstance.baseUrl)
        XCTAssertEqual(configInstance.anonKey, retrievedInstance.anonKey)
    }
    
    func testConfigWithCustomStorageUrl() throws {
        let config = SelfDBConfig(
            baseUrl: "https://api.example.com",
            storageUrl: "https://storage.example.com",
            anonKey: "test-key"
        )
        
        XCTAssertEqual(config.baseUrl, "https://api.example.com")
        XCTAssertEqual(config.storageUrl, "https://storage.example.com")
    }
    
    // MARK: - Client Creation Tests
    
    func testClientCreation() async throws {
        let config = SelfDBConfig(
            baseUrl: "http://localhost:8000",
            anonKey: "test-key"
        )
        
        let client = try await createClient(config: config)
        
        XCTAssertNotNil(client.auth)
        XCTAssertNotNil(client.db)
        XCTAssertNotNil(client.storage)
        XCTAssertNotNil(client.realtime)
    }
    
    // MARK: - Auth Types Tests
    
    func testAuthTokensEquality() {
        let tokens1 = AuthTokens(accessToken: "token1", refreshToken: "refresh1")
        let tokens2 = AuthTokens(accessToken: "token1", refreshToken: "refresh1")
        let tokens3 = AuthTokens(accessToken: "token2", refreshToken: "refresh2")
        
        XCTAssertEqual(tokens1, tokens2)
        XCTAssertNotEqual(tokens1, tokens3)
    }
    
    func testUserEquality() {
        let user1 = User(
            id: "123",
            email: "test@example.com",
            isActive: true,
            isSuperuser: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: nil
        )
        
        let user2 = User(
            id: "123",
            email: "test@example.com",
            isActive: true,
            isSuperuser: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: nil
        )
        
        XCTAssertEqual(user1, user2)
    }
    
    func testLoginResponseUserComputed() {
        let loginResponse = LoginResponse(
            accessToken: "access123",
            tokenType: "bearer",
            refreshToken: "refresh123",
            isSuperuser: false,
            email: "test@example.com",
            userId: "user123"
        )
        
        let user = loginResponse.user
        XCTAssertEqual(user.id, "user123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.isSuperuser, false)
        XCTAssertTrue(user.isActive) // Should default to true for logged in users
    }
    
    // MARK: - Database Types Tests
    
    func testQueryOptionsCreation() {
        let options = QueryOptions(
            where: ["status": AnyCodable("active")],
            orderBy: [OrderBy(column: "created_at", direction: .desc)],
            limit: 10,
            offset: 20
        )
        
        XCTAssertEqual(options.limit, 10)
        XCTAssertEqual(options.offset, 20)
        XCTAssertEqual(options.orderBy?.first?.column, "created_at")
        XCTAssertEqual(options.orderBy?.first?.direction, .desc)
    }
    
    func testPaginatedResponse() {
        struct TestItem: Codable {
            let id: String
            let name: String
        }
        
        let items = [
            TestItem(id: "1", name: "Item 1"),
            TestItem(id: "2", name: "Item 2")
        ]
        
        let paginated = PaginatedResponse(
            data: items,
            total: 100,
            page: 1,
            limit: 10,
            hasNext: true,
            hasPrev: false
        )
        
        XCTAssertEqual(paginated.data.count, 2)
        XCTAssertEqual(paginated.total, 100)
        XCTAssertTrue(paginated.hasNext)
        XCTAssertFalse(paginated.hasPrev)
    }
    
    // MARK: - Storage Types Tests
    
    func testCreateBucketRequest() throws {
        let request = CreateBucketRequest(
            name: "test-bucket",
            isPublic: true,
            description: "Test bucket"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["name"] as? String, "test-bucket")
        XCTAssertEqual(json?["is_public"] as? Bool, true)
        XCTAssertEqual(json?["description"] as? String, "Test bucket")
    }
    
    func testFileMetadata() {
        let metadata = FileMetadata(
            id: "file123",
            filename: "document.pdf",
            contentType: "application/pdf",
            bucketName: "test-bucket",
            objectName: "file123.pdf",
            size: 1024,
            ownerId: "user123",
            bucketId: "bucket123",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: nil
        )
        
        XCTAssertEqual(metadata.id, "file123")
        XCTAssertEqual(metadata.filename, "document.pdf")
        XCTAssertEqual(metadata.contentType, "application/pdf")
        XCTAssertEqual(metadata.bucketName, "test-bucket")
        XCTAssertEqual(metadata.objectName, "file123.pdf")
        XCTAssertEqual(metadata.size, 1024)
        XCTAssertEqual(metadata.ownerId, "user123")
        XCTAssertEqual(metadata.bucketId, "bucket123")
        XCTAssertEqual(metadata.createdAt, "2024-01-01T00:00:00Z")
        XCTAssertNil(metadata.updatedAt)
    }
    
    // MARK: - Error Handling Tests
    
    func testSelfDBErrorCreation() {
        let error = SelfDBError(
            message: "Test error",
            code: "TEST_ERROR",
            suggestion: "Try again",
            status: 400
        )
        
        XCTAssertEqual(error.errorDescription, "Test error")
        XCTAssertEqual(error.code, "TEST_ERROR")
        XCTAssertEqual(error.suggestion, "Try again")
        XCTAssertEqual(error.status, 400)
        XCTAssertFalse(error.isRetryable())
    }
    
    func testApiErrorRetryable() {
        let error500 = ApiError("Server error", status: 500)
        let error400 = ApiError("Bad request", status: 400)
        
        XCTAssertTrue(error500.isRetryable())
        XCTAssertFalse(error400.isRetryable())
    }
    
    // MARK: - Integration Tests (Requires running backend)
    
    func testEndToEndFlow() async throws {
        // Skip if not running against real backend
        guard ProcessInfo.processInfo.environment["SELFDB_TEST_BACKEND"] != nil else {
            throw XCTSkip("Set SELFDB_TEST_BACKEND environment variable to run integration tests")
        }
        
        // Use environment variables for test configuration
        let baseUrl = ProcessInfo.processInfo.environment["SELFDB_BASE_URL"] ?? "http://localhost:8000"
        let storageUrl = ProcessInfo.processInfo.environment["SELFDB_STORAGE_URL"] ?? "http://localhost:8001"
        let anonKey = ProcessInfo.processInfo.environment["SELFDB_ANON_KEY"] ?? ""
        
        let config = SelfDBConfig(
            baseUrl: baseUrl,
            storageUrl: storageUrl,
            anonKey: anonKey
        )
        
        let client = try await createClient(config: config)
        
        // Generate unique test email
        let testEmail = "test_\(UUID().uuidString.lowercased())@example.com"
        let testPassword = "testpassword123"
        
        // Test registration
        let user = try await client.auth.register(
            credentials: RegisterRequest(
                email: testEmail,
                password: testPassword
            )
        )
        
        XCTAssertEqual(user.email, testEmail)
        XCTAssertTrue(user.isActive)
        
        // Test login
        let loginResponse = try await client.auth.login(
            credentials: LoginRequest(
                email: testEmail,
                password: testPassword
            )
        )
        
        XCTAssertEqual(loginResponse.email, testEmail)
        XCTAssertNotNil(loginResponse.accessToken)
        XCTAssertNotNil(loginResponse.refreshToken)
        
        // Test authenticated request
        let currentUser = try await client.auth.getUser()
        XCTAssertEqual(currentUser?.email, testEmail)
        
        // Test database operations
        let tables = try await client.db.listTables()
        XCTAssertTrue(tables.contains { $0.name == "users" })
        
        // Clean up - logout
        try await client.auth.logout()
    }
}

// MARK: - Test Helpers

extension SelfDBTests {
    
    /// Create a mock configuration for testing
    static func mockConfig() -> SelfDBConfig {
        return SelfDBConfig(
            baseUrl: "http://localhost:8000",
            anonKey: "mock-anon-key",
            headers: ["X-Test": "true"]
        )
    }
    
    /// Assert that an async operation throws a specific error type
    func assertThrowsError<T, E: Error>(
        _ expression: @autoclosure () async throws -> T,
        errorType: E.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error of type \(errorType) but no error was thrown", file: file, line: line)
        } catch is E {
            // Success - correct error type thrown
        } catch {
            XCTFail("Expected error of type \(errorType) but got \(type(of: error))", file: file, line: line)
        }
    }
}
