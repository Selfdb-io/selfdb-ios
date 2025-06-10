import XCTest
@testable import SelfDB

final class DatabaseTests: XCTestCase {
    var client: SelfDB!
    let testConfig = SelfDBConfig(
        apiURL: URL(string: "http://localhost:8000/api/v1")!,
        storageURL: URL(string: "http://localhost:8001")!,
        apiKey: "f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"
    )
    
    override func setUp() {
        super.setUp()
        client = SelfDB(config: testConfig)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testTableInfoStructure() {
        let tableInfo = TableInfo(
            name: "test_table",
            description: "Test table",
            size: 1048576,
            column_count: 5
        )
        
        XCTAssertEqual(tableInfo.name, "test_table")
        XCTAssertEqual(tableInfo.description, "Test table")
        XCTAssertEqual(tableInfo.size, 1048576)
        XCTAssertEqual(tableInfo.column_count, 5)
    }
    
    func testColumnInfoStructure() {
        let columnInfo = ColumnInfo(
            column_name: "id",
            data_type: "integer",
            is_nullable: "NO",
            column_default: nil,
            character_maximum_length: nil,
            numeric_precision: nil,
            numeric_scale: nil,
            column_description: nil
        )
        
        XCTAssertEqual(columnInfo.column_name, "id")
        XCTAssertEqual(columnInfo.data_type, "integer")
        XCTAssertEqual(columnInfo.is_nullable, "NO")
        XCTAssertNil(columnInfo.column_default)
    }
    
    func testTableDetailsStructure() {
        let columns = [
            ColumnInfo(column_name: "id", data_type: "integer", is_nullable: "NO", column_default: nil, character_maximum_length: nil, numeric_precision: nil, numeric_scale: nil, column_description: nil),
            ColumnInfo(column_name: "name", data_type: "varchar", is_nullable: "YES", column_default: nil, character_maximum_length: 255, numeric_precision: nil, numeric_scale: nil, column_description: nil)
        ]
        
        let indexes = [
            IndexInfo(index_name: "primary", column_name: "id", is_unique: true, is_primary: true)
        ]
        
        let tableDetails = TableDetails(
            name: "test_table",
            description: "Test table",
            columns: columns,
            primary_keys: ["id"],
            foreign_keys: [],
            indexes: indexes,
            row_count: 100
        )
        
        XCTAssertEqual(tableDetails.name, "test_table")
        XCTAssertEqual(tableDetails.columns.count, 2)
        XCTAssertEqual(tableDetails.description, "Test table")
        XCTAssertEqual(tableDetails.row_count, 100)
    }
    
    func testCreateTableRequest() {
        let columns = [
            CreateColumnRequest(name: "id", type: "SERIAL", nullable: false, primaryKey: true),
            CreateColumnRequest(name: "name", type: "VARCHAR(255)", nullable: false),
            CreateColumnRequest(name: "price", type: "DECIMAL(10,2)", nullable: true)
        ]
        
        let request = CreateTableRequest(
            name: "test_products",
            columns: columns,
            description: "Test products table"
        )
        
        XCTAssertEqual(request.name, "test_products")
        XCTAssertEqual(request.columns.count, 3)
        XCTAssertEqual(request.description, "Test products table")
        
        // Test first column
        let firstColumn = request.columns[0]
        XCTAssertEqual(firstColumn.name, "id")
        XCTAssertEqual(firstColumn.type, "SERIAL")
        XCTAssertFalse(firstColumn.nullable)
        XCTAssertEqual(firstColumn.primary_key, true)
    }
    
    func testUpdateTableRequest() {
        let request = UpdateTableRequest(description: "Updated test table")
        XCTAssertEqual(request.description, "Updated test table")
    }
    
    func testTableDataResponse() {
        let data = [
            ["id": AnyCodable(1), "name": AnyCodable("Test Product")],
            ["id": AnyCodable(2), "name": AnyCodable("Another Product")]
        ]
        
        let columns = [
            TableDataColumn(column_name: "id", data_type: "integer", is_nullable: "NO"),
            TableDataColumn(column_name: "name", data_type: "varchar", is_nullable: "YES")
        ]
        
        let metadata = TableDataMetadata(
            total_count: 2,
            page: 1,
            page_size: 10,
            total_pages: 1,
            columns: columns
        )
        
        let response = TableDataResponse(
            data: data,
            metadata: metadata
        )
        
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.metadata.total_count, 2)
        XCTAssertEqual(response.metadata.page, 1)
        XCTAssertEqual(response.metadata.page_size, 10)
        XCTAssertEqual(response.metadata.total_pages, 1)
    }
    
    func testAnyCodableWithString() {
        let stringValue = AnyCodable("test string")
        XCTAssertTrue(stringValue.value is String)
        
        // Test encoding/decoding
        do {
            let encoded = try JSONEncoder().encode(stringValue)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            XCTAssertTrue(decoded.value is String)
            XCTAssertEqual(decoded.value as? String, "test string")
        } catch {
            XCTFail("Failed to encode/decode AnyCodable string: \(error)")
        }
    }
    
    func testAnyCodableWithNumber() {
        let numberValue = AnyCodable(42)
        XCTAssertTrue(numberValue.value is Int)
        
        // Test encoding/decoding
        do {
            let encoded = try JSONEncoder().encode(numberValue)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            XCTAssertTrue(decoded.value is Int)
            XCTAssertEqual(decoded.value as? Int, 42)
        } catch {
            XCTFail("Failed to encode/decode AnyCodable number: \(error)")
        }
    }
    
    func testAnyCodableWithBool() {
        let boolValue = AnyCodable(true)
        XCTAssertTrue(boolValue.value is Bool)
        
        // Test encoding/decoding
        do {
            let encoded = try JSONEncoder().encode(boolValue)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            XCTAssertTrue(decoded.value is Bool)
            XCTAssertEqual(decoded.value as? Bool, true)
        } catch {
            XCTFail("Failed to encode/decode AnyCodable bool: \(error)")
        }
    }
}