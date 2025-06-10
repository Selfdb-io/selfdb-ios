import Foundation

/// Database types and models
public struct TableInfo: Codable {
    public let name: String
    public let description: String?
    public let size: Int
    public let column_count: Int
    
    public init(name: String, description: String?, size: Int, column_count: Int) {
        self.name = name
        self.description = description
        self.size = size
        self.column_count = column_count
    }
}

public struct TableDetails: Codable {
    public let name: String
    public let description: String
    public let columns: [ColumnInfo]
    public let primary_keys: [String]
    public let foreign_keys: [String] // Should be array of objects in real API, but keeping simple for now
    public let indexes: [IndexInfo]
    public let row_count: Int
    
    public init(name: String, description: String, columns: [ColumnInfo], primary_keys: [String], foreign_keys: [String], indexes: [IndexInfo], row_count: Int) {
        self.name = name
        self.description = description
        self.columns = columns
        self.primary_keys = primary_keys
        self.foreign_keys = foreign_keys
        self.indexes = indexes
        self.row_count = row_count
    }
}

public struct ColumnInfo: Codable {
    public let column_name: String
    public let data_type: String
    public let is_nullable: String
    public let column_default: String?
    public let character_maximum_length: Int?
    public let numeric_precision: Int?
    public let numeric_scale: Int?
    public let column_description: String?
    
    public init(column_name: String, data_type: String, is_nullable: String, column_default: String?, character_maximum_length: Int?, numeric_precision: Int?, numeric_scale: Int?, column_description: String?) {
        self.column_name = column_name
        self.data_type = data_type
        self.is_nullable = is_nullable
        self.column_default = column_default
        self.character_maximum_length = character_maximum_length
        self.numeric_precision = numeric_precision
        self.numeric_scale = numeric_scale
        self.column_description = column_description
    }
}

public struct IndexInfo: Codable {
    public let index_name: String
    public let column_name: String
    public let is_unique: Bool
    public let is_primary: Bool
    
    public init(index_name: String, column_name: String, is_unique: Bool, is_primary: Bool) {
        self.index_name = index_name
        self.column_name = column_name
        self.is_unique = is_unique
        self.is_primary = is_primary
    }
}

public struct TableDataMetadata: Codable {
    public let total_count: Int
    public let page: Int
    public let page_size: Int
    public let total_pages: Int
    public let columns: [TableDataColumn]
    
    public init(total_count: Int, page: Int, page_size: Int, total_pages: Int, columns: [TableDataColumn]) {
        self.total_count = total_count
        self.page = page
        self.page_size = page_size
        self.total_pages = total_pages
        self.columns = columns
    }
}

public struct TableDataColumn: Codable {
    public let column_name: String
    public let data_type: String
    public let is_nullable: String
    
    public init(column_name: String, data_type: String, is_nullable: String) {
        self.column_name = column_name
        self.data_type = data_type
        self.is_nullable = is_nullable
    }
}

public struct TableDataResponse: Codable {
    public let data: [[String: AnyCodable]]
    public let metadata: TableDataMetadata
    
    public init(data: [[String: AnyCodable]], metadata: TableDataMetadata) {
        self.data = data
        self.metadata = metadata
    }
}

public struct CreateTableRequest: Codable {
    public let name: String
    public let description: String?
    public let if_not_exists: Bool?
    public let columns: [CreateColumnRequest]
    
    public init(name: String, columns: [CreateColumnRequest], description: String? = nil, if_not_exists: Bool? = true) {
        self.name = name
        self.columns = columns
        self.description = description
        self.if_not_exists = if_not_exists
    }
}

public struct CreateColumnRequest: Codable {
    public let name: String
    public let type: String
    public let nullable: Bool
    public let primary_key: Bool?
    public let `default`: String?
    public let description: String?
    
    public init(name: String, type: String, nullable: Bool = true, primaryKey: Bool? = nil, defaultValue: String? = nil, description: String? = nil) {
        self.name = name
        self.type = type
        self.nullable = nullable
        self.primary_key = primaryKey
        self.`default` = defaultValue
        self.description = description
    }
}

public struct CreateTableResponse: Codable {
    public let message: String
    public let created: Bool
    public let name: String
    public let columns: [CreateTableColumnResponse]
    
    public init(message: String, created: Bool, name: String, columns: [CreateTableColumnResponse]) {
        self.message = message
        self.created = created
        self.name = name
        self.columns = columns
    }
}

public struct CreateTableColumnResponse: Codable {
    public let name: String
    public let type: String
    public let nullable: Bool
    public let `default`: String?
    public let primary_key: Bool
    public let description: String?
    public let is_foreign_key: Bool
    public let references_table: String?
    public let references_column: String?
    
    public init(name: String, type: String, nullable: Bool, defaultValue: String?, primary_key: Bool, description: String?, is_foreign_key: Bool, references_table: String?, references_column: String?) {
        self.name = name
        self.type = type
        self.nullable = nullable
        self.`default` = defaultValue
        self.primary_key = primary_key
        self.description = description
        self.is_foreign_key = is_foreign_key
        self.references_table = references_table
        self.references_column = references_column
    }
}

public struct UpdateTableRequest: Codable {
    public let description: String
    
    public init(description: String) {
        self.description = description
    }
}

public struct UpdateTableResponse: Codable {
    public let message: String
    public let description: String
    
    public init(message: String, description: String) {
        self.message = message
        self.description = description
    }
}

public struct DeleteTableResponse: Codable {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

/// AnyCodable wrapper for dynamic JSON values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.init(NSNull())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

/// Database client for table operations
public class DatabaseClient {
    private let httpClient = HTTPClient()
    private let authClient: AuthClient
    
    public init(authClient: AuthClient) {
        self.authClient = authClient
    }
    
    // MARK: - Table Operations
    
    /// List all tables
    /// - Returns: Array of table information
    public func listTables() async -> SelfDBResponse<[TableInfo]> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/tables",
            headers: headers,
            responseType: [TableInfo].self
        )
    }
    
    /// Get table details
    /// - Parameter tableName: Name of the table
    /// - Returns: Table details including columns
    public func getTable(_ tableName: String) async -> SelfDBResponse<TableDetails> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/tables/\(tableName)",
            headers: headers,
            responseType: TableDetails.self
        )
    }
    
    /// Get table data with pagination
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - page: Page number (default: 1)
    ///   - pageSize: Page size (default: 10)
    /// - Returns: Paginated table data
    public func getTableData(_ tableName: String, page: Int = 1, pageSize: Int = 10) async -> SelfDBResponse<TableDataResponse> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/tables/\(tableName)/data?page=\(page)&page_size=\(pageSize)",
            headers: headers,
            responseType: TableDataResponse.self
        )
    }
    
    /// Get table data with pagination **and optional filtering**
    public func getTableData(
        _ tableName: String,
        page: Int = 1,
        pageSize: Int = 10,
        filterColumn: String? = nil,
        filterValue: String? = nil,
        orderBy: String? = nil
    ) async -> SelfDBResponse<TableDataResponse> {
        let headers = authClient.getAuthHeaders()
        
        // Build query-string
        var endpoint = "/tables/\(tableName)/data?page=\(page)&page_size=\(pageSize)"
        if let col = filterColumn,
           let val = filterValue,
           !col.isEmpty {
            let encCol = col.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? col
            let encVal = val.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? val
            endpoint += "&filter_column=\(encCol)&filter_value=\(encVal)"
        }
        if let order = orderBy, !order.isEmpty {
            let encOrder = order.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? order
            endpoint += "&order_by=\(encOrder)"
        }
        
        return await httpClient.request(
            endpoint: endpoint,
            headers: headers,
            responseType: TableDataResponse.self
        )
    }
    
    /// Create a new table
    /// - Parameter request: Table creation request
    /// - Returns: Created table information
    @discardableResult
    public func createTable(_ request: CreateTableRequest) async -> SelfDBResponse<CreateTableResponse> {
        do {
            let body = try JSONEncoder().encode(request)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/tables",
                method: .POST,
                body: body,
                headers: headers,
                responseType: CreateTableResponse.self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Update table description
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - request: Update request
    /// - Returns: Updated table information
    @discardableResult
    public func updateTable(_ tableName: String, _ request: UpdateTableRequest) async -> SelfDBResponse<UpdateTableResponse> {
        do {
            let body = try JSONEncoder().encode(request)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/tables/\(tableName)",
                method: .PUT,
                body: body,
                headers: headers,
                responseType: UpdateTableResponse.self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Delete a table
    /// - Parameter tableName: Name of the table
    /// - Returns: Deletion result
    @discardableResult
    public func deleteTable(_ tableName: String) async -> SelfDBResponse<DeleteTableResponse> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/tables/\(tableName)",
            method: .DELETE,
            headers: headers,
            responseType: DeleteTableResponse.self
        )
    }
    
    // MARK: - Row Operations
    
    /// Insert data into table
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - data: Data to insert
    /// - Returns: Insert result
    @discardableResult
    public func insertRow(_ tableName: String, data: [String: Any]) async -> SelfDBResponse<[String: AnyCodable]> {
        do {
            let anyCodableData = data.mapValues { AnyCodable($0) }
            let body = try JSONEncoder().encode(anyCodableData)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/tables/\(tableName)/data",
                method: .POST,
                body: body,
                headers: headers,
                responseType: [String: AnyCodable].self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Update row in table
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - rowId: ID of the row to update
    ///   - data: Data to update
    /// - Returns: Update result
    @discardableResult
    public func updateRow(_ tableName: String, rowId: String, data: [String: Any]) async -> SelfDBResponse<[String: AnyCodable]> {
        do {
            let anyCodableData = data.mapValues { AnyCodable($0) }
            let body = try JSONEncoder().encode(anyCodableData)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/tables/\(tableName)/data/\(rowId)?id_column=id",
                method: .PUT,
                body: body,
                headers: headers,
                responseType: [String: AnyCodable].self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Delete row from table
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - rowId: ID of the row to delete
    ///   - idColumn: Primary-key column name (defaults to `"id"`)
    /// - Returns: Deletion result
    @discardableResult
    public func deleteRow(
        _ tableName: String,
        rowId: String,
        idColumn: String = "id"
    ) async -> SelfDBResponse<EmptyResponse> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/tables/\(tableName)/data/\(rowId)?id_column=\(idColumn)",
            method: .DELETE,
            headers: headers
        )
    }
}