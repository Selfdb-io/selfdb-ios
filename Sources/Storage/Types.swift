import Foundation
import Core

/// Bucket model
public struct Bucket: Codable, Identifiable {
    public let id: String
    public let name: String
    public let isPublic: Bool
    public let description: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let userId: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isPublic = "is_public"
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

/// Request to create a new bucket
public struct CreateBucketRequest: Codable {
    public let name: String
    public let isPublic: Bool?
    public let description: String?
    
    public init(name: String, isPublic: Bool? = nil, description: String? = nil) {
        self.name = name
        self.isPublic = isPublic
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case isPublic = "is_public"
        case description
    }
}

/// Request to update a bucket
public struct UpdateBucketRequest: Codable {
    public let name: String?
    public let isPublic: Bool?
    public let description: String?
    
    public init(name: String? = nil, isPublic: Bool? = nil, description: String? = nil) {
        self.name = name
        self.isPublic = isPublic
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case isPublic = "is_public"
        case description
    }
}

/// File metadata model
public struct FileMetadata: Codable, Identifiable {
    public let id: String
    public let filename: String
    public let contentType: String
    public let size: Int
    public let bucketId: String
    public let userId: String
    public let createdAt: Date
    public let updatedAt: Date
    public let metadata: [String: AnyCodable]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case filename
        case contentType = "content_type"
        case size
        case bucketId = "bucket_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case metadata
    }
}

/// Options for uploading files
public struct UploadFileOptions {
    public let metadata: [String: Any]?
    public let contentType: String?
    
    public init(metadata: [String: Any]? = nil, contentType: String? = nil) {
        self.metadata = metadata
        self.contentType = contentType
    }
}

/// Options for listing files
public struct FileListOptions {
    public let limit: Int?
    public let offset: Int?
    public let search: String?
    
    public init(limit: Int? = nil, offset: Int? = nil, search: String? = nil) {
        self.limit = limit
        self.offset = offset
        self.search = search
    }
}

/// Response from file upload
public struct FileUploadResponse: Codable {
    public let file: FileMetadata
    public let uploadUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case file
        case uploadUrl = "upload_url"
    }
}

/// Response for file download info
public struct FileDownloadInfoResponse: Codable {
    public let fileMetadata: FileMetadata
    public let downloadUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case downloadUrl = "download_url"
    }
}

/// Response for file view info
public struct FileViewInfoResponse: Codable {
    public let fileMetadata: FileMetadata
    public let viewUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case viewUrl = "view_url"
    }
}

/// Progress callback for uploads
public typealias ProgressCallback = (Double) -> Void

/// AnyCodable for file metadata
public struct AnyCodable: Codable {
    public let value: Any
    
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