import XCTest
@testable import SelfDB
@testable import Core

final class SelfDBTests: XCTestCase {
    
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
}
