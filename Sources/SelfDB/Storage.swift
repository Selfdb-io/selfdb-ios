import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Storage types and models
public struct Bucket: Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let is_public: Bool
    public let minio_bucket_name: String
    public let owner_id: String
    public let created_at: String
    public let updated_at: String?
    public let file_count: Int?
    public let total_size: Int?
    
    public init(id: String, name: String, description: String?, is_public: Bool, minio_bucket_name: String, owner_id: String, created_at: String, updated_at: String?, file_count: Int?, total_size: Int?) {
        self.id = id
        self.name = name
        self.description = description
        self.is_public = is_public
        self.minio_bucket_name = minio_bucket_name
        self.owner_id = owner_id
        self.created_at = created_at
        self.updated_at = updated_at
        self.file_count = file_count
        self.total_size = total_size
    }
}

public struct CreateBucketRequest: Codable {
    public let name: String
    public let description: String?
    public let is_public: Bool
    
    public init(name: String, description: String? = nil, isPublic: Bool = false) {
        self.name = name
        self.description = description
        self.is_public = isPublic
    }
}

public struct UpdateBucketRequest: Codable {
    public let description: String?
    public let is_public: Bool?
    
    public init(description: String? = nil, isPublic: Bool? = nil) {
        self.description = description
        self.is_public = isPublic
    }
}

public struct FileInfo: Codable {
    public let id: String
    public let filename: String
    public let content_type: String
    public let size: Int
    public let bucket_id: String
    public let created_at: String
    public let updated_at: String
    public let is_public: Bool?
    
    public init(id: String, filename: String, content_type: String, size: Int, bucket_id: String, created_at: String, updated_at: String, is_public: Bool?) {
        self.id = id
        self.filename = filename
        self.content_type = content_type
        self.size = size
        self.bucket_id = bucket_id
        self.created_at = created_at
        self.updated_at = updated_at
        self.is_public = is_public
    }
}

public struct InitiateUploadRequest: Codable {
    public let filename: String
    public let content_type: String
    public let size: Int
    public let bucket_id: String
    
    public init(filename: String, contentType: String, size: Int, bucketId: String) {
        self.filename = filename
        self.content_type = contentType
        self.size = size
        self.bucket_id = bucketId
    }
}

public struct FileMetadata: Codable {
    public let filename: String
    public let content_type: String
    public let id: String
    public let bucket_name: String
    public let object_name: String
    public let size: Int
    public let owner_id: String
    public let bucket_id: String
    public let created_at: String
    public let updated_at: String?
    
    public init(filename: String, content_type: String, id: String, bucket_name: String, object_name: String, size: Int, owner_id: String, bucket_id: String, created_at: String, updated_at: String?) {
        self.filename = filename
        self.content_type = content_type
        self.id = id
        self.bucket_name = bucket_name
        self.object_name = object_name
        self.size = size
        self.owner_id = owner_id
        self.bucket_id = bucket_id
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

public struct PresignedUploadInfo: Codable {
    public let upload_url: String
    public let upload_method: String
    
    public init(upload_url: String, upload_method: String) {
        self.upload_url = upload_url
        self.upload_method = upload_method
    }
}

public struct InitiateUploadResponse: Codable {
    public let file_metadata: FileMetadata
    public let presigned_upload_info: PresignedUploadInfo
    
    public init(file_metadata: FileMetadata, presigned_upload_info: PresignedUploadInfo) {
        self.file_metadata = file_metadata
        self.presigned_upload_info = presigned_upload_info
    }
}

public struct FileDownloadInfo: Codable {
    public let file_metadata: FileMetadata
    public let download_url: String
    
    public init(file_metadata: FileMetadata, download_url: String) {
        self.file_metadata = file_metadata
        self.download_url = download_url
    }
}

public struct FileViewInfo: Codable {
    public let file_metadata: FileMetadata
    public let view_url: String
    
    public init(file_metadata: FileMetadata, view_url: String) {
        self.file_metadata = file_metadata
        self.view_url = view_url
    }
}

/// Storage client for bucket and file operations
public class StorageClient {
    private let httpClient = HTTPClient()
    private let authClient: AuthClient
    
    public init(authClient: AuthClient) {
        self.authClient = authClient
    }
    
    // MARK: - Bucket Operations
    
    /// List all buckets
    /// - Returns: Array of buckets
    public func listBuckets() async -> SelfDBResponse<[Bucket]> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/buckets",
            headers: headers,
            responseType: [Bucket].self
        )
    }
    
    /// Create a new bucket
    /// - Parameter request: Bucket creation request
    /// - Returns: Created bucket information
    @discardableResult
    public func createBucket(_ request: CreateBucketRequest) async -> SelfDBResponse<Bucket> {
        do {
            let body = try JSONEncoder().encode(request)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/buckets",
                method: .POST,
                body: body,
                headers: headers,
                responseType: Bucket.self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Get bucket details
    /// - Parameter bucketId: Bucket ID
    /// - Returns: Bucket information
    public func getBucket(_ bucketId: String) async -> SelfDBResponse<Bucket> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/buckets/\(bucketId)",
            headers: headers,
            responseType: Bucket.self
        )
    }
    
    /// Update bucket
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - request: Update request
    /// - Returns: Updated bucket information
    @discardableResult
    public func updateBucket(_ bucketId: String, _ request: UpdateBucketRequest) async -> SelfDBResponse<Bucket> {
        do {
            let body = try JSONEncoder().encode(request)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/buckets/\(bucketId)",
                method: .PUT,
                body: body,
                headers: headers,
                responseType: Bucket.self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// List files in a bucket
    /// - Parameter bucketId: Bucket ID
    /// - Returns: Array of files
    public func listBucketFiles(_ bucketId: String) async -> SelfDBResponse<[FileInfo]> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/buckets/\(bucketId)/files",
            headers: headers,
            responseType: [FileInfo].self
        )
    }
    
    // MARK: - File Operations
    
    /// List user files
    /// - Returns: Array of files
    public func listFiles() async -> SelfDBResponse<[FileInfo]> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/files",
            headers: headers,
            responseType: [FileInfo].self
        )
    }
    
    /// Initiate file upload
    /// - Parameter request: Upload initiation request
    /// - Returns: Upload information with presigned URL
    public func initiateUpload(_ request: InitiateUploadRequest) async -> SelfDBResponse<InitiateUploadResponse> {
        do {
            let body = try JSONEncoder().encode(request)
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "application/json"
            
            return await httpClient.request(
                endpoint: "/files/initiate-upload",
                method: .POST,
                body: body,
                headers: headers,
                responseType: InitiateUploadResponse.self
            )
        } catch {
            return SelfDBResponse(data: nil, error: .encodingError(error), statusCode: 0)
        }
    }
    
    /// Upload file data to presigned URL
    /// - Parameters:
    ///   - data: File data
    ///   - uploadURL: Presigned upload URL
    ///   - contentType: Content type
    /// - Returns: Upload result
    public func uploadData(_ data: Data, to uploadURL: String, contentType: String) async -> SelfDBResponse<EmptyResponse> {
        do {
            guard let url = URL(string: uploadURL) else {
                return SelfDBResponse(data: nil, error: .invalidURL, statusCode: 0)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = data
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SelfDBResponse(data: nil, error: .invalidResponse, statusCode: 0)
            }
            
            let statusCode = httpResponse.statusCode
            if statusCode >= 200 && statusCode < 300 {
                return SelfDBResponse(data: EmptyResponse(), error: nil, statusCode: statusCode)
            } else {
                return SelfDBResponse(data: nil, error: .httpError(statusCode: statusCode, message: nil), statusCode: statusCode)
            }
            
        } catch {
            return SelfDBResponse(data: nil, error: .networkError(error), statusCode: 0)
        }
    }
    
    /// Get file download information
    /// - Parameter fileId: File ID
    /// - Returns: Download information
    public func getFileDownloadInfo(_ fileId: String) async -> SelfDBResponse<FileDownloadInfo> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/files/\(fileId)/download-info",
            headers: headers,
            responseType: FileDownloadInfo.self
        )
    }
    
    /// Get file view information
    /// - Parameter fileId: File ID
    /// - Returns: View information
    public func getFileViewInfo(_ fileId: String) async -> SelfDBResponse<FileViewInfo> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/files/\(fileId)/view-info",
            headers: headers,
            responseType: FileViewInfo.self
        )
    }
    
    /// Get public file download information
    /// - Parameter fileId: File ID
    /// - Returns: Download information
    public func getPublicFileDownloadInfo(_ fileId: String) async -> SelfDBResponse<FileDownloadInfo> {
        return await httpClient.request(
            endpoint: "/files/public/\(fileId)/download-info",
            responseType: FileDownloadInfo.self
        )
    }
    
    /// Get public file view information
    /// - Parameter fileId: File ID
    /// - Returns: View information
    public func getPublicFileViewInfo(_ fileId: String) async -> SelfDBResponse<FileViewInfo> {
        return await httpClient.request(
            endpoint: "/files/public/\(fileId)/view-info",
            responseType: FileViewInfo.self
        )
    }
    
    /// Delete file
    /// - Parameter fileId: File ID
    /// - Returns: Deletion result
    @discardableResult
    public func deleteFile(_ fileId: String) async -> SelfDBResponse<EmptyResponse> {
        let headers = authClient.getAuthHeaders()
        return await httpClient.request(
            endpoint: "/files/\(fileId)",
            method: .DELETE,
            headers: headers
        )
    }
}