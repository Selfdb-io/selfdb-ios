import Foundation
import Core
import Auth

/// Helper for encoding [String: Any] as JSON
private struct AnyEncodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [String: Any] {
            let encoded = value.mapValues { AnyEncodable($0) }
            try container.encode(encoded)
        } else if let value = value as? [Any] {
            let encoded = value.map { AnyEncodable($0) }
            try container.encode(encoded)
        } else {
            try container.encodeNil()
        }
    }
    
    init(from decoder: Decoder) throws {
        // This is just for encoding, so we don't need decoding
        value = NSNull()
    }
}

/// Database client for SelfDB CRUD operations
public final class DatabaseClient {
    private let authClient: AuthClient
    
    public init(authClient: AuthClient) {
        self.authClient = authClient
    }
    
    /// List all tables in the database
    /// - Returns: Array of table information
    /// - Throws: SelfDB errors
    public func listTables() async throws -> [TableInfo] {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/tables"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to list tables: \(error.localizedDescription)",
                code: "LIST_TABLES_ERROR",
                suggestion: "Check your authentication and network connection"
            )
        }
    }
    
    /// Get detailed information about a table
    /// - Parameter tableName: Name of the table
    /// - Returns: Table details including columns, keys, and indexes
    /// - Throws: SelfDB errors
    public func getTableDetails(tableName: String) async throws -> TableDetails {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/tables/\(tableName)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get table details: \(error.localizedDescription)",
                code: "TABLE_DETAILS_ERROR",
                suggestion: "Check that the table '\(tableName)' exists"
            )
        }
    }
    
    /// Create a new record in a table
    /// - Parameters:
    ///   - table: Table name
    ///   - data: Data to insert
    /// - Returns: The created record
    /// - Throws: SelfDB errors
    public func create<T: Codable>(
        table: String,
        data: [String: Any]
    ) async throws -> T {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/tables/\(table)/data",
                body: data.mapValues { AnyEncodable($0) }
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Create operation failed: \(error.localizedDescription)",
                code: "CREATE_ERROR",
                suggestion: "Check your data types and table constraints"
            )
        }
    }
    
    /// Read records from a table
    /// - Parameters:
    ///   - table: Table name
    ///   - options: Query options
    /// - Returns: Array of records
    /// - Throws: SelfDB errors
    public func read<T: Codable>(
        table: String,
        options: QueryOptions = QueryOptions()
    ) async throws -> [T] {
        var params: [String: String] = [:]
        
        if let limit = options.limit {
            params["page_size"] = String(limit)
        }
        
        if let offset = options.offset {
            let page = (offset / (options.limit ?? 50)) + 1
            params["page"] = String(page)
        }
        
        if let orderBy = options.orderBy, let firstOrder = orderBy.first {
            params["order_by"] = "\(firstOrder.column):\(firstOrder.direction.rawValue)"
        }
        
        // Add filtering (limited support for simple where conditions)
        if let whereClause = options.where, let firstCondition = whereClause.first {
            params["filter_column"] = firstCondition.key
            params["filter_value"] = String(describing: firstCondition.value.value)
        }
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let path = "/api/v1/tables/\(table)/data" + (queryString.isEmpty ? "" : "?\(queryString)")
        
        do {
            let response: TableDataResponse<T> = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: path
            )
            return response.data
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Read operation failed: \(error.localizedDescription)",
                code: "READ_ERROR",
                suggestion: "Check your table name and query parameters"
            )
        }
    }
    
    /// Update a record in a table
    /// - Parameters:
    ///   - table: Table name
    ///   - data: Data to update
    ///   - where: Where conditions (currently only supports id-based updates)
    /// - Returns: The updated record
    /// - Throws: SelfDB errors
    public func update<T: Codable>(
        table: String,
        data: [String: Any],
        where conditions: [String: Any]
    ) async throws -> T {
        // For now, support simple id-based updates
        guard let idValue = conditions["id"] else {
            throw SelfDBError(
                message: "Update currently only supports id-based where conditions",
                code: "UPDATE_UNSUPPORTED_WHERE",
                suggestion: "Use id in where conditions for updates"
            )
        }
        
        let path = "/api/v1/tables/\(table)/data/\(idValue)?id_column=id"
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .PUT,
                path: path,
                body: data.mapValues { AnyEncodable($0) }
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Update operation failed: \(error.localizedDescription)",
                code: "UPDATE_ERROR",
                suggestion: "Check your data types and where conditions"
            )
        }
    }
    
    /// Delete a record from a table
    /// - Parameters:
    ///   - table: Table name
    ///   - where: Where conditions (currently only supports id-based deletes)
    /// - Returns: Delete response with message and deleted data
    /// - Throws: SelfDB errors
    public func delete(
        table: String,
        where conditions: [String: Any]
    ) async throws -> DeleteResponse {
        // For now, support simple id-based deletes
        guard let idValue = conditions["id"] else {
            throw SelfDBError(
                message: "Delete currently only supports id-based where conditions",
                code: "DELETE_UNSUPPORTED_WHERE",
                suggestion: "Use id in where conditions for deletes"
            )
        }
        
        let path = "/api/v1/tables/\(table)/data/\(idValue)?id_column=id"
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .DELETE,
                path: path
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Delete operation failed: \(error.localizedDescription)",
                code: "DELETE_ERROR",
                suggestion: "Check your where conditions"
            )
        }
    }
    
    /// Backward compatibility method that returns Bool
    /// - Parameters:
    ///   - table: Table name
    ///   - where: Where conditions
    /// - Returns: True if successful
    /// - Throws: SelfDB errors
    public func deleteRecord(
        table: String,
        where conditions: [String: Any]
    ) async throws -> Bool {
        do {
            _ = try await delete(table: table, where: conditions)
            return true
        } catch {
            throw error
        }
    }
    
    /// Find a record by ID
    /// - Parameters:
    ///   - table: Table name
    ///   - id: Record ID
    /// - Returns: The record, or nil if not found
    /// - Throws: SelfDB errors
    public func findById<T: Codable>(
        table: String,
        id: Any
    ) async throws -> T? {
        let results: [T] = try await read(
            table: table,
            options: QueryOptions(where: ["id": AnyCodable(id)])
        )
        return results.first
    }
    
    /// Paginate records from a table
    /// - Parameters:
    ///   - table: Table name
    ///   - page: Page number (1-based)
    ///   - limit: Records per page
    ///   - options: Additional query options
    /// - Returns: Paginated response
    /// - Throws: SelfDB errors
    public func paginate<T: Codable>(
        table: String,
        page: Int = 1,
        limit: Int = 10,
        options: QueryOptions = QueryOptions()
    ) async throws -> PaginatedResponse<T> {
        var params: [String: String] = [
            "page": String(page),
            "page_size": String(limit)
        ]
        
        if let orderBy = options.orderBy, let firstOrder = orderBy.first {
            params["order_by"] = "\(firstOrder.column):\(firstOrder.direction.rawValue)"
        }
        
        // Add filtering (limited support for simple where conditions)
        if let whereClause = options.where, let firstCondition = whereClause.first {
            params["filter_column"] = firstCondition.key
            params["filter_value"] = String(describing: firstCondition.value.value)
        }
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let path = "/api/v1/tables/\(table)/data?\(queryString)"
        
        do {
            let response: TableDataResponse<T> = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: path
            )
            
            return PaginatedResponse(
                data: response.data,
                total: response.metadata.totalCount,
                page: response.metadata.page,
                limit: response.metadata.pageSize,
                hasNext: response.metadata.page < response.metadata.totalPages,
                hasPrev: response.metadata.page > 1
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Paginate operation failed: \(error.localizedDescription)",
                code: "PAGINATE_ERROR",
                suggestion: "Check your table name and query parameters"
            )
        }
    }
    
    /// Execute raw SQL query
    /// - Parameters:
    ///   - query: SQL query string
    ///   - params: Query parameters
    /// - Returns: SQL query response
    /// - Throws: SelfDB errors
    public func executeSql(
        query: String,
        params: [Any] = []
    ) async throws -> SqlQueryResponse {
        let request = SqlQueryRequest(
            query: query,
            params: params.map { AnyCodable($0) }
        )
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/sql/query",
                body: request
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "SQL execution failed: \(error.localizedDescription)",
                code: "SQL_ERROR",
                suggestion: "Check your SQL syntax and parameters"
            )
        }
    }
}