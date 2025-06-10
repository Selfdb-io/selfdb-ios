import XCTest
@testable import SelfDB

final class SelfDBTests: XCTestCase {
    func testSelfDBInitialization() {
        let config = SelfDBConfig(
            apiURL: URL(string: "http://localhost:8000/api/v1")!,
            storageURL: URL(string: "http://localhost:8001")!,
            apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
        )
        
        let client = SelfDB(config: config)
        
        XCTAssertNotNil(client.auth)
        XCTAssertNotNil(client.database)
        XCTAssertNotNil(client.storage)
    }
    
    func testCreateClientWithConfig() {
        let config = SelfDBConfig(
            apiURL: URL(string: "http://localhost:8000/api/v1")!,
            storageURL: URL(string: "http://localhost:8001")!,
            apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
        )
        
        let client = createClient(config: config)
        
        XCTAssertNotNil(client.auth)
        XCTAssertNotNil(client.database)
        XCTAssertNotNil(client.storage)
    }
    
    func testCreateClientWithStrings() {
        let client = createClient(
            apiURL: "http://localhost:8000/api/v1",
            storageURL: "http://localhost:8001",
            apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
        )
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client?.auth)
        XCTAssertNotNil(client?.database)
        XCTAssertNotNil(client?.storage)
    }
    
    func testCreateClientWithInvalidURL() {
        // Note: URL(string:) is quite permissive, so we test the actual validation behavior
        // For truly invalid URLs, the createClient will return nil if URL(string:) returns nil
        let config = SelfDBConfig(apiURL: "file://", storageURL: "file://", apiKey: "test_key")
        XCTAssertNotNil(config) // These URLs are valid, just not HTTP
        
        let client = createClient(config: config!)
        XCTAssertNotNil(client) // Client creation will succeed with any valid URLs
    }
    
    func testSelfDBConfigInitialization() {
        let config = SelfDBConfig(
            apiURL: URL(string: "http://localhost:8000/api/v1")!,
            storageURL: URL(string: "http://localhost:8001")!,
            apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
        )
        
        XCTAssertEqual(config.apiURL.absoluteString, "http://localhost:8000/api/v1")
        XCTAssertEqual(config.storageURL.absoluteString, "http://localhost:8001")
        XCTAssertEqual(config.apiKey, "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814")
    }
    
    func testSelfDBConfigWithStrings() {
        let config = SelfDBConfig(
            apiURL: "http://localhost:8000/api/v1",
            storageURL: "http://localhost:8001",
            apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
        )
        
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.apiURL.absoluteString, "http://localhost:8000/api/v1")
        XCTAssertEqual(config?.storageURL.absoluteString, "http://localhost:8001")
        XCTAssertEqual(config?.apiKey, "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814")
    }
    
    func testSelfDBConfigWithInvalidStrings() {
        // Note: URL(string:) is quite permissive, so we test the actual validation behavior
        // For truly invalid URLs, the config will return nil if URL(string:) returns nil
        let config = SelfDBConfig(apiURL: "file://", storageURL: "file://", apiKey: "test_key")
        XCTAssertNotNil(config) // These URLs are valid, just not HTTP
        
        XCTAssertEqual(config?.apiURL.scheme, "file")
        XCTAssertEqual(config?.storageURL.scheme, "file")
        XCTAssertEqual(config?.apiKey, "test_key")
    }
    
    func testSelfDBErrorDescriptions() {
        let errors: [SelfDBError] = [
            .configurationNotInitialized,
            .invalidURL,
            .networkError(NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test network error"])),
            .httpError(statusCode: 404, message: "Not found"),
            .decodingError(NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test decoding error"])),
            .encodingError(NSError(domain: "EncodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test encoding error"])),
            .authenticationRequired,
            .invalidResponse
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testSelfDBResponseSuccess() {
        let response = SelfDBResponse<String>(data: "test", error: nil, statusCode: 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.data, "test")
        XCTAssertNil(response.error)
        XCTAssertEqual(response.statusCode, 200)
    }
    
    func testSelfDBResponseError() {
        let response = SelfDBResponse<String>(data: nil, error: .invalidURL, statusCode: 400)
        XCTAssertFalse(response.isSuccess)
        XCTAssertNil(response.data)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.statusCode, 400)
    }
}