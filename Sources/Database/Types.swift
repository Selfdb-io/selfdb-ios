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
        public let columns: [String]
        
        private enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
            case page
            case pageSize = "page_size"
            case totalPages = "total_pages"
            case columns
        }
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