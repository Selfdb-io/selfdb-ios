import XCTest
@testable import SelfDB

final class AuthenticationIntegrationTests: XCTestCase {
    var client: SelfDB!
    let logger = IntegrationTestLogger.shared
    let state = IntegrationTestState.shared
    
    override func setUp() {
        super.setUp()
        client = SelfDB(config: IntegrationTestConfig.testConfig)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testInitialization() {
        logger.logTestHeader("Authentication Client Initialization")
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.auth)
        XCTAssertNil(client.auth.accessToken)
        
        let result = TestResult(
            testName: "testInitialization",
            description: "Initialize Authentication Client",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testRegistrationDataStructure() {
        logger.logTestHeader("Registration Data Structure")
        
        let registerRequest = RegisterRequest(
            email: "test@example.com",
            password: "password123"
        )
        
        XCTAssertEqual(registerRequest.email, "test@example.com")
        XCTAssertEqual(registerRequest.password, "password123")
        
        let result = TestResult(
            testName: "testRegistrationDataStructure",
            description: "Registration Request Structure",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testLoginDataStructure() {
        logger.logTestHeader("Login Data Structure")
        
        let loginRequest = LoginRequest(
            username: "test@example.com",
            password: "password123"
        )
        
        XCTAssertEqual(loginRequest.username, "test@example.com")
        XCTAssertEqual(loginRequest.password, "password123")
        
        let result = TestResult(
            testName: "testLoginDataStructure",
            description: "Login Request Structure",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testAuthResponseStructure() {
        logger.logTestHeader("Authentication Response Structure")
        
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
        
        let result = TestResult(
            testName: "testAuthResponseStructure",
            description: "Authentication Response Structure",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testUserStructure() {
        logger.logTestHeader("User Data Structure")
        
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
        
        let result = TestResult(
            testName: "testUserStructure",
            description: "User Data Structure",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testSignOut() {
        logger.logTestHeader("Sign Out")
        
        client.auth.signOut()
        XCTAssertNil(client.auth.accessToken)
        
        let result = TestResult(
            testName: "testSignOut",
            description: "Sign Out",
            success: true
        )
        logger.logTestResult(result)
    }
    
    func testRealAuthentication() async {
        logger.logTestHeader("Real Authentication Against SelfDB Instance")
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let testEmail = "\(IntegrationTestConfig.testEmailBase)_\(timestamp)@example.com"
        
        // Test registration
        let registerResult = await client.auth.register(
            email: testEmail,
            password: IntegrationTestConfig.testPassword
        )
        
        var registrationSuccess = false
        
        if registerResult.isSuccess, let user = registerResult.data {
            registrationSuccess = true
            // Registration doesn't return tokens, only user info
            state.userId = user.id
            state.testEmail = testEmail
            logger.logTestResult(TestResult(
                testName: "testRealAuthentication",
                description: "User Registration",
                success: true,
                statusCode: registerResult.statusCode
            ))
            
            // Test login
            let loginResult = await client.auth.login(
                email: testEmail,
                password: IntegrationTestConfig.testPassword
            )
            
            if loginResult.isSuccess, let loginResponse = loginResult.data {
                state.accessToken = loginResponse.access_token
                logger.logTestResult(TestResult(
                    testName: "testRealAuthentication",
                    description: "User Login",
                    success: true,
                    statusCode: loginResult.statusCode
                ))
            } else {
                logger.logTestResult(TestResult(
                    testName: "testRealAuthentication",
                    description: "User Login",
                    success: false,
                    statusCode: loginResult.statusCode,
                    error: loginResult.error?.localizedDescription
                ))
            }
            
        } else {
            registrationSuccess = false
            logger.logTestResult(TestResult(
                testName: "testRealAuthentication",
                description: "User Registration",
                success: false,
                statusCode: registerResult.statusCode,
                error: registerResult.error?.localizedDescription
            ))
        }
        
        XCTAssertTrue(registrationSuccess, "Registration should succeed")
    }
    
    func testAllAuthentication() async {
        await testRealAuthentication()
    }
}