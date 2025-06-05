import Foundation
import Core

/// Bucket model - matches backend BucketWithStats
public struct Bucket: Codable, Identifiable {
    public let id: String
    public let name: String
    public let isPublic: Bool
    public let description: String?
    public let createdAt: String
    public let updatedAt: String?
    public let ownerId: String
    public let minioBucketName: String?
    
    // Stats fields
    public let fileCount: Int?
    public let totalSize: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isPublic = "is_public"
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case ownerId = "owner_id"
        case minioBucketName = "minio_bucket_name"
        case fileCount = "file_count"
        case totalSize = "total_size"
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

/// File metadata model - matches backend File schema
public struct FileMetadata: Codable, Identifiable {
    public let id: String
    public let filename: String
    public let contentType: String?
    public let bucketName: String
    public let objectName: String
    public let size: Int64?
    public let ownerId: String
    public let bucketId: String?
    public let createdAt: String
    public let updatedAt: String?
    
    public init(
        id: String,
        filename: String,
        contentType: String? = nil,
        bucketName: String,
        objectName: String,
        size: Int64? = nil,
        ownerId: String,
        bucketId: String? = nil,
        createdAt: String,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.bucketName = bucketName
        self.objectName = objectName
        self.size = size
        self.ownerId = ownerId
        self.bucketId = bucketId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case filename
        case contentType = "content_type"
        case bucketName = "bucket_name"
        case objectName = "object_name"
        case size
        case ownerId = "owner_id"
        case bucketId = "bucket_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Bucket information (alias for compatibility)
public typealias BucketInfo = Bucket

/// Detailed bucket information with stats
public struct BucketDetails: Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let isPublic: Bool
    public let minioBucketName: String
    public let ownerId: String
    public let createdAt: String
    public let updatedAt: String?
    public let fileCount: Int
    public let totalSize: Int64
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isPublic = "is_public"
        case minioBucketName = "minio_bucket_name"
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case fileCount = "file_count"
        case totalSize = "total_size"
    }
}

/// Upload file options
public struct UploadFileOptions {
    public let contentType: String?
    
    public init(contentType: String? = nil) {
        self.contentType = contentType
    }
}

/// File upload request for initiating upload
public struct FileUploadInitiateRequest: Codable {
    public let filename: String
    public let contentType: String
    public let size: Int
    public let bucketId: String
    
    public init(filename: String, contentType: String, size: Int, bucketId: String) {
        self.filename = filename
        self.contentType = contentType
        self.size = size
        self.bucketId = bucketId
    }
    
    private enum CodingKeys: String, CodingKey {
        case filename
        case contentType = "content_type"
        case size
        case bucketId = "bucket_id"
    }
}

/// Presigned upload information
public struct PresignedUploadInfo: Codable {
    public let uploadUrl: String
    public let uploadMethod: String
    
    private enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case uploadMethod = "upload_method"
    }
}

/// File upload initiate response
public struct FileUploadInitiateResponse: Codable {
    public let fileMetadata: FileMetadata
    public let presignedUploadInfo: PresignedUploadInfo
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case presignedUploadInfo = "presigned_upload_info"
    }
}

/// File upload response
public struct FileUploadResponse: Codable {
    public let file: FileMetadata
    public let uploadUrl: String?
    
    public init(file: FileMetadata, uploadUrl: String? = nil) {
        self.file = file
        self.uploadUrl = uploadUrl
    }
    
    private enum CodingKeys: String, CodingKey {
        case file
        case uploadUrl = "upload_url"
    }
}

/// Request to initiate file upload
public struct InitiateUploadRequest: Codable {
    public let filename: String
    public let contentType: String
    public let size: Int64
    public let bucketId: String
    
    private enum CodingKeys: String, CodingKey {
        case filename
        case contentType = "content_type"
        case size
        case bucketId = "bucket_id"
    }
}

/// Response from initiate upload
public struct InitiateUploadResponse: Codable {
    public let fileMetadata: FileMetadata
    public let presignedUploadInfo: PresignedUploadInfo
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case presignedUploadInfo = "presigned_upload_info"
    }
}

/// File download information
public struct DownloadInfo: Codable {
    public let fileMetadata: FileMetadata
    public let downloadUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case downloadUrl = "download_url"
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

/// Response for file view info (unwrapped)
public struct FileViewInfoResponse: Codable {
    public let fileMetadata: FileMetadata
    public let viewUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case fileMetadata = "file_metadata"
        case viewUrl = "view_url"
    }
}

/// Wrapped response for file view info (matches JS SDK structure)
public struct WrappedFileViewInfoResponse: Codable {
    public let data: FileViewInfoResponse
}

/// Wrapped response for file download info (matches JS SDK structure)
public struct WrappedFileDownloadInfoResponse: Codable {
    public let data: FileDownloadInfoResponse
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