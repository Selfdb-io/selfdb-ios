import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Core
import Auth

/// Storage client for SelfDB file and bucket operations
public final class StorageClient {
    private let authClient: AuthClient
    private let config: Config
    
    public init(authClient: AuthClient) throws {
        self.authClient = authClient
        self.config = try Config.getInstance()
    }
    
    // MARK: - Bucket Operations
    
    /// List all buckets
    /// - Returns: Array of buckets
    /// - Throws: SelfDB errors
    public func listBuckets() async throws -> [Bucket] {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/storage/buckets"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to list buckets: \(error.localizedDescription)",
                code: "BUCKET_LIST_ERROR",
                suggestion: "Check your authentication and permissions"
            )
        }
    }
    
    /// Create a new bucket
    /// - Parameter request: Bucket creation request
    /// - Returns: Created bucket
    /// - Throws: SelfDB errors
    public func createBucket(_ request: CreateBucketRequest) async throws -> Bucket {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/storage/buckets",
                body: request
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to create bucket: \(error.localizedDescription)",
                code: "BUCKET_CREATE_ERROR",
                suggestion: "Check bucket name uniqueness and permissions"
            )
        }
    }
    
    /// Get bucket by ID
    /// - Parameter bucketId: Bucket ID
    /// - Returns: Bucket details
    /// - Throws: SelfDB errors
    public func getBucket(bucketId: String) async throws -> Bucket {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/storage/buckets/\(bucketId)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get bucket: \(error.localizedDescription)",
                code: "BUCKET_GET_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Update bucket
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - request: Update request
    /// - Returns: Updated bucket
    /// - Throws: SelfDB errors
    public func updateBucket(bucketId: String, _ request: UpdateBucketRequest) async throws -> Bucket {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .PUT,
                path: "/api/v1/storage/buckets/\(bucketId)",
                body: request
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to update bucket: \(error.localizedDescription)",
                code: "BUCKET_UPDATE_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Delete bucket
    /// - Parameter bucketId: Bucket ID
    /// - Returns: True if successful
    /// - Throws: SelfDB errors
    public func deleteBucket(bucketId: String) async throws -> Bool {
        do {
            let _: EmptyResponse = try await authClient.makeAuthenticatedRequest(
                method: .DELETE,
                path: "/api/v1/storage/buckets/\(bucketId)"
            )
            return true
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to delete bucket: \(error.localizedDescription)",
                code: "BUCKET_DELETE_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Find bucket by name
    /// - Parameter name: Bucket name
    /// - Returns: Bucket ID, or nil if not found
    /// - Throws: SelfDB errors
    public func findBucketByName(_ name: String) async throws -> String? {
        let buckets = try await listBuckets()
        return buckets.first { $0.name == name }?.id
    }
    
    // MARK: - File Operations
    
    /// Upload a file to a bucket
    /// - Parameters:
    ///   - bucketName: Name of the bucket
    ///   - fileData: File data to upload
    ///   - filename: Name for the file
    ///   - options: Upload options
    /// - Returns: Upload response
    /// - Throws: SelfDB errors
    public func upload(
        bucket bucketName: String,
        file fileData: Data,
        filename: String,
        options: UploadFileOptions = UploadFileOptions()
    ) async throws -> FileUploadResponse {
        // Find bucket by name
        guard let bucketId = try await findBucketByName(bucketName) else {
            throw SelfDBError(
                message: "Bucket '\(bucketName)' not found",
                code: "BUCKET_NOT_FOUND",
                suggestion: "Create the bucket first or check the bucket name"
            )
        }
        
        return try await uploadToBucket(
            bucketId: bucketId,
            fileData: fileData,
            filename: filename,
            options: options
        )
    }
    
    /// Upload a file to a bucket by ID
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - fileData: File data to upload
    ///   - filename: Name for the file
    ///   - options: Upload options
    /// - Returns: Upload response
    /// - Throws: SelfDB errors
    public func uploadToBucket(
        bucketId: String,
        fileData: Data,
        filename: String,
        options: UploadFileOptions = UploadFileOptions()
    ) async throws -> FileUploadResponse {
        do {
            // Create multipart form data
            let boundary = UUID().uuidString
            let httpBody = createMultipartBody(
                fileData: fileData,
                filename: filename,
                boundary: boundary,
                contentType: options.contentType
            )
            
            var headers = authClient.getAuthHeaders()
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
            
            // Make request directly with URLSession for multipart upload
            let config = try Config.getInstance()
            let url = URL(string: "\(config.storageUrl)/api/v1/storage/buckets/\(bucketId)/files")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = httpBody
            
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let session = URLSession.shared
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError("Invalid response received")
            }
            
            if httpResponse.statusCode >= 400 {
                throw ApiError("Upload failed", status: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(FileUploadResponse.self, from: data)
            
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Upload failed: \(error.localizedDescription)",
                code: "UPLOAD_ERROR",
                suggestion: "Check your file and bucket permissions"
            )
        }
    }
    
    /// List files in a bucket
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - options: List options
    /// - Returns: Array of file metadata
    /// - Throws: SelfDB errors
    public func listFiles(bucketId: String, options: FileListOptions = FileListOptions()) async throws -> [FileMetadata] {
        var params: [String: String] = [:]
        
        if let limit = options.limit {
            params["limit"] = String(limit)
        }
        
        if let offset = options.offset {
            params["offset"] = String(offset)
        }
        
        if let search = options.search {
            params["search"] = search
        }
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let path = "/api/v1/storage/buckets/\(bucketId)/files" + (queryString.isEmpty ? "" : "?\(queryString)")
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: path
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to list files: \(error.localizedDescription)",
                code: "FILE_LIST_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Delete a file by ID
    /// - Parameter fileId: File ID
    /// - Returns: True if successful
    /// - Throws: SelfDB errors
    public func deleteFile(fileId: String) async throws -> Bool {
        do {
            let _: EmptyResponse = try await authClient.makeAuthenticatedRequest(
                method: .DELETE,
                path: "/api/v1/storage/files/\(fileId)"
            )
            return true
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to delete file: \(error.localizedDescription)",
                code: "FILE_DELETE_ERROR",
                suggestion: "Check file ID and permissions"
            )
        }
    }
    
    /// Get file download URL
    /// - Parameters:
    ///   - bucketName: Bucket name
    ///   - fileId: File ID
    /// - Returns: Download URL
    /// - Throws: SelfDB errors
    public func getUrl(bucket bucketName: String, fileId: String) async throws -> String {
        guard let bucketId = try await findBucketByName(bucketName) else {
            throw SelfDBError(
                message: "Bucket '\(bucketName)' not found",
                code: "BUCKET_NOT_FOUND",
                suggestion: "Check the bucket name"
            )
        }
        
        return try await getFileUrl(bucketId: bucketId, fileId: fileId)
    }
    
    /// Get file download URL by bucket ID
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - fileId: File ID
    /// - Returns: Download URL
    /// - Throws: SelfDB errors
    public func getFileUrl(bucketId: String, fileId: String) async throws -> String {
        do {
            let response: FileDownloadInfoResponse = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/storage/buckets/\(bucketId)/files/\(fileId)/download"
            )
            return response.downloadUrl
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get file URL: \(error.localizedDescription)",
                code: "URL_ERROR",
                suggestion: "Check the file ID and bucket ID"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create multipart form data for file upload
    private func createMultipartBody(
        fileData: Data,
        filename: String,
        boundary: String,
        contentType: String?
    ) -> Data {
        var body = Data()
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType ?? "application/octet-stream")\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}