import XCTest
@testable import SelfDB

final class AuthenticationTests: XCTestCase {
    var client: SelfDB!
    let testConfig = SelfDBConfig(
        apiURL: URL(string: "http://localhost:8000/api/v1")!,
        storageURL: URL(string: "http://localhost:8001")!,
        apiKey: "your-anon-key-here"
    )
    
    override func setUp() {
        super.setUp()
        client = SelfDB(config: testConfig)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.auth)
        XCTAssertNil(client.auth.accessToken)
    }
    
    func testRegistrationDataStructure() {
        let registerRequest = RegisterRequest(
            email: "test@example.com",
            password: "password123"
        )
        
        XCTAssertEqual(registerRequest.email, "test@example.com")
        XCTAssertEqual(registerRequest.password, "password123")
    }
    
    func testLoginDataStructure() {
        let loginRequest = LoginRequest(
            username: "test@example.com",
            password: "password123"
        )
        
        XCTAssertEqual(loginRequest.username, "test@example.com")
        XCTAssertEqual(loginRequest.password, "password123")
    }
    
    func testAuthResponseStructure() {
        let authResponse = AuthResponse(
            access_token: "test_token",
            refresh_token: "refresh_token",
            token_type: "bearer",
            user_id: "user123",
            email: "test@example.com",
            is_superuser: false
        )
        
        XCTAssertEqual(authResponse.access_token, "test_token")
        XCTAssertEqual(authResponse.refresh_token, "refresh_token")
        XCTAssertEqual(authResponse.token_type, "bearer")
        XCTAssertEqual(authResponse.user_id, "user123")
    }
    
    func testUserStructure() {
        let user = User(
            id: "123",
            email: "test@example.com",
            is_active: true,
            is_superuser: false,
            created_at: "2024-01-01T00:00:00Z",
            updated_at: "2024-01-01T00:00:00Z"
        )
        
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertTrue(user.is_active)
    }
    
    func testSignOut() {
        client.auth.signOut()
        XCTAssertNil(client.auth.accessToken)
    }
}