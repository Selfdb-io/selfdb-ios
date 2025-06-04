import Foundation
import Core
import Auth

/// Query options for database operations
public struct QueryOptions: Codable {
    public let select: [String]?
    public let `where`: [String: AnyCodable]?
    public let orderBy: [OrderBy]?
    public let limit: Int?
    public let offset: Int?
    
    public init(
        select: [String]? = nil,
        where: [String: AnyCodable]? = nil,
        orderBy: [OrderBy]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.select = select
        self.where = `where`
        self.orderBy = orderBy
        self.limit = limit
        self.offset = offset
    }
}

/// Order by clause for database queries
public struct OrderBy: Codable {
    public let column: String
    public let direction: Direction
    
    public init(column: String, direction: Direction = .asc) {
        self.column = column
        self.direction = direction
    }
    
    public enum Direction: String, Codable {
        case asc = "asc"
        case desc = "desc"
    }
}

/// Type-erased wrapper for any Codable value
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [String: AnyCodable] {
            try container.encode(value)
        } else if let value = value as? [AnyCodable] {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }
}

/// Paginated response wrapper
public struct PaginatedResponse<T: Codable>: Codable {
    public let data: [T]
    public let total: Int
    public let page: Int
    public let limit: Int
    public let hasNext: Bool
    public let hasPrev: Bool
}

/// Table data response from API
public struct TableDataResponse<T: Codable>: Codable {
    public let data: [T]
    public let metadata: Metadata
    
    public struct Metadata: Codable {
        public let totalCount: Int
        public let page: Int
        public let pageSize: Int
        public let totalPages: Int
        public let columns: [ColumnInfo]
        
        private enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
            case page
            case pageSize = "page_size"
            case totalPages = "total_pages"
            case columns
        }
    }
}

/// Column information from the backend
public struct ColumnInfo: Codable {
    public let columnName: String
    public let dataType: String
    public let isNullable: String
    
    private enum CodingKeys: String, CodingKey {
        case columnName = "column_name"
        case dataType = "data_type"
        case isNullable = "is_nullable"
    }
}

/// Table information
public struct TableInfo: Codable {
    public let name: String
    public let description: String?
    public let size: Int?
    public let columnCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case size
        case columnCount = "column_count"
    }
}

/// Table details response
public struct TableDetails: Codable {
    public let name: String
    public let description: String?
    public let columns: [ColumnDetails]
    public let primaryKeys: [String]
    public let foreignKeys: [ForeignKeyInfo]
    public let indexes: [IndexInfo]
    public let rowCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case columns
        case primaryKeys = "primary_keys"
        case foreignKeys = "foreign_keys"
        case indexes
        case rowCount = "row_count"
    }
}

/// Detailed column information
public struct ColumnDetails: Codable {
    public let columnName: String
    public let dataType: String
    public let isNullable: String
    public let columnDefault: String?
    public let characterMaximumLength: Int?
    public let numericPrecision: Int?
    public let numericScale: Int?
    public let columnDescription: String?
    
    private enum CodingKeys: String, CodingKey {
        case columnName = "column_name"
        case dataType = "data_type"
        case isNullable = "is_nullable"
        case columnDefault = "column_default"
        case characterMaximumLength = "character_maximum_length"
        case numericPrecision = "numeric_precision"
        case numericScale = "numeric_scale"
        case columnDescription = "column_description"
    }
}

/// Foreign key information
public struct ForeignKeyInfo: Codable {
    public let columnName: String
    public let foreignTableName: String
    public let foreignColumnName: String
    
    private enum CodingKeys: String, CodingKey {
        case columnName = "column_name"
        case foreignTableName = "foreign_table_name"
        case foreignColumnName = "foreign_column_name"
    }
}

/// Index information
public struct IndexInfo: Codable {
    public let indexName: String
    public let columnName: String
    public let isUnique: Bool
    public let isPrimary: Bool
    
    private enum CodingKeys: String, CodingKey {
        case indexName = "index_name"
        case columnName = "column_name"
        case isUnique = "is_unique"
        case isPrimary = "is_primary"
    }
}

/// SQL query request
public struct SqlQueryRequest: Codable {
    public let query: String
    public let params: [AnyCodable]?
    
    public init(query: String, params: [AnyCodable]? = nil) {
        self.query = query
        self.params = params
    }
}

/// SQL query response
public struct SqlQueryResponse: Codable {
    public let columns: [String]
    public let rows: [[AnyCodable]]
    public let rowCount: Int
    public let duration: Double
    
    private enum CodingKeys: String, CodingKey {
        case columns
        case rows
        case rowCount = "row_count"
        case duration
    }
}

/// Delete operation response
public struct DeleteResponse: Codable {
    public let message: String
    public let deletedData: [String: AnyCodable]
    
    private enum CodingKeys: String, CodingKey {
        case message
        case deletedData = "deleted_data"
    }
}