import Foundation
@testable import SelfDB

/// Configuration for integration tests against real SelfDB instance
public struct IntegrationTestConfig {
    static let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "http://localhost:8000/api/v1"
    static let storageURL = ProcessInfo.processInfo.environment["STORAGE_URL"] ?? "http://localhost:8001"
    static let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
    
    static let testEmailBase = "swifttest"
    static let testPassword = "password123"
    
    // Admin credentials for admin operations
    static let adminEmail = "admin@example.com"
    static let adminPassword = "adminpassword"
    
    static var testConfig: SelfDBConfig {
        return SelfDBConfig(
            apiURL: URL(string: backendURL)!,
            storageURL: URL(string: storageURL)!,
            apiKey: apiKey
        )
    }
}

/// Test state and tracking
public class IntegrationTestState {
    static let shared = IntegrationTestState()
    
    var accessToken: String?
    var userId: String?
    var testEmail: String?
    var adminAccessToken: String?
    var adminUserId: String?
    var createdTableNames: [String] = []
    var createdBucketIds: [String] = []
    var createdFileIds: [String] = []
    var createdFunctionIds: [String] = []
    
    var testResults: [TestResult] = []
    var testLogFile: FileHandle?
    var testLogFilename: String?
    
    private init() {}
    
    func reset() {
        accessToken = nil
        userId = nil
        testEmail = nil
        adminAccessToken = nil
        adminUserId = nil
        createdTableNames.removeAll()
        createdBucketIds.removeAll()
        createdFileIds.removeAll()
        createdFunctionIds.removeAll()
        testResults.removeAll()
    }
}

/// Individual test result
public struct TestResult {
    let testName: String
    let description: String
    let success: Bool
    let statusCode: Int?
    let error: String?
    let timestamp: Date
    
    init(testName: String, description: String, success: Bool, statusCode: Int? = nil, error: String? = nil) {
        self.testName = testName
        self.description = description
        self.success = success
        self.statusCode = statusCode
        self.error = error
        self.timestamp = Date()
    }
}