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
    /// - Returns: Array of buckets with stats
    /// - Throws: SelfDB errors
    public func listBuckets() async throws -> [Bucket] {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/buckets"
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
                path: "/api/v1/buckets",
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
                path: "/api/v1/buckets/\(bucketId)"
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
                path: "/api/v1/buckets/\(bucketId)",
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
                path: "/api/v1/buckets/\(bucketId)"
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
    
    /// Find bucket by name (case-insensitive to match JS SDK)
    /// - Parameter name: Bucket name
    /// - Returns: Bucket, or nil if not found
    /// - Throws: SelfDB errors
    public func findBucketByName(_ name: String) async throws -> Bucket? {
        let buckets = try await listBuckets()
        return buckets.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - File Operations
    
    /// Upload a file to a bucket using presigned URL approach (matches JS SDK pattern)
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
        guard let bucket = try await findBucketByName(bucketName) else {
            throw SelfDBError(
                message: "Bucket '\(bucketName)' not found",
                code: "BUCKET_NOT_FOUND",
                suggestion: "Create the bucket first or check the bucket name"
            )
        }
        
        do {
            // Step 1: Initiate upload to get presigned URL
            let initiateRequest = FileUploadInitiateRequest(
                filename: filename,
                contentType: options.contentType,
                size: fileData.count,
                bucketId: bucket.id
            )
            
            let initiateResponse: FileUploadInitiateResponse = try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/files/initiate-upload",
                body: initiateRequest
            )
            
            // Step 2: Upload file to presigned URL
            try await uploadToPresignedUrl(
                presignedInfo: initiateResponse.presignedUploadInfo,
                fileData: fileData,
                contentType: options.contentType
            )
            
            // Return the file metadata in the expected format
            return FileUploadResponse(file: initiateResponse.fileMetadata, uploadUrl: nil)
            
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Upload failed: \(error.localizedDescription)",
                code: "UPLOAD_ERROR",
                suggestion: "Check your file and bucket permissions"
            )
        }
    }
    
    /// Upload a file to a bucket by ID using presigned URL approach
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - fileData: File data to upload
    ///   - filename: Name for the file
    ///   - options: Upload options
    /// - Returns: File metadata
    /// - Throws: SelfDB errors
    public func uploadToBucket(
        bucketId: String,
        fileData: Data,
        filename: String,
        options: UploadFileOptions = UploadFileOptions()
    ) async throws -> FileMetadata {
        do {
            // Step 1: Initiate upload to get presigned URL
            let initiateRequest = FileUploadInitiateRequest(
                filename: filename,
                contentType: options.contentType,
                size: fileData.count,
                bucketId: bucketId
            )
            
            let initiateResponse: FileUploadInitiateResponse = try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/files/initiate-upload",
                body: initiateRequest
            )
            
            // Step 2: Upload file to presigned URL
            try await uploadToPresignedUrl(
                presignedInfo: initiateResponse.presignedUploadInfo,
                fileData: fileData,
                contentType: options.contentType
            )
            
            // Return the file metadata
            return initiateResponse.fileMetadata
            
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Upload failed: \(error.localizedDescription)",
                code: "UPLOAD_ERROR",
                suggestion: "Check your file and bucket permissions"
            )
        }
    }
    
    /// Upload file data to presigned URL
    private func uploadToPresignedUrl(
        presignedInfo: PresignedUploadInfo,
        fileData: Data,
        contentType: String?
    ) async throws {
        guard let url = URL(string: presignedInfo.uploadUrl) else {
            throw SelfDBError(
                message: "Invalid presigned URL",
                code: "INVALID_URL",
                suggestion: "Contact support if this persists"
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = presignedInfo.uploadMethod
        request.httpBody = fileData
        
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        let session = URLSession.shared
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError("Invalid response received")
        }
        
        if httpResponse.statusCode >= 400 {
            throw ApiError("Presigned upload failed", status: httpResponse.statusCode)
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
            params["skip"] = String(offset)
        }
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let path = "/api/v1/buckets/\(bucketId)/files" + (queryString.isEmpty ? "" : "?\(queryString)")
        
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
                path: "/api/v1/files/\(fileId)"
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
    /// - Parameter fileId: File ID
    /// - Returns: Download URL
    /// - Throws: SelfDB errors
    public func getDownloadUrl(fileId: String) async throws -> String {
        do {
            let response: FileDownloadInfoResponse = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/\(fileId)/download-info"
            )
            return response.downloadUrl
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get download URL: \(error.localizedDescription)",
                code: "DOWNLOAD_URL_ERROR",
                suggestion: "Check the file ID and permissions"
            )
        }
    }
    
    /// Get file view URL
    /// - Parameter fileId: File ID
    /// - Returns: View URL
    /// - Throws: SelfDB errors
    public func getViewUrl(fileId: String) async throws -> String {
        do {
            let response: FileViewInfoResponse = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/\(fileId)/view-info"
            )
            return response.viewUrl
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get view URL: \(error.localizedDescription)",
                code: "VIEW_URL_ERROR",
                suggestion: "Check the file ID and permissions"
            )
        }
    }
    
    /// Get public file view URL (for public buckets) - matches JS SDK getPublicFileViewInfo
    /// - Parameter fileId: File ID
    /// - Returns: Public view URL
    /// - Throws: SelfDB errors
    public func getPublicViewUrl(fileId: String) async throws -> String {
        do {
            let response: FileViewInfoResponse = try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/public/\(fileId)/view-info"
            )
            return response.viewUrl
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get public view URL: \(error.localizedDescription)",
                code: "PUBLIC_VIEW_URL_ERROR",
                suggestion: "Check the file ID and ensure it's in a public bucket"
            )
        }
    }
    
    /// Get public file view info (for public buckets) - matches JS SDK getPublicFileViewInfo
    /// - Parameter fileId: File ID
    /// - Returns: FileViewInfoResponse with metadata and view URL
    /// - Throws: SelfDB errors
    public func getPublicFileViewInfo(fileId: String) async throws -> FileViewInfoResponse {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/public/\(fileId)/view-info"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get public file view info: \(error.localizedDescription)",
                code: "PUBLIC_VIEW_URL_ERROR",
                suggestion: "Check the file ID and ensure it's in a public bucket"
            )
        }
    }
    
    /// Get file view info (authenticated) - matches JS SDK getFileViewInfo
    /// - Parameter fileId: File ID
    /// - Returns: FileViewInfoResponse with metadata and view URL
    /// - Throws: SelfDB errors
    public func getFileViewInfo(fileId: String) async throws -> FileViewInfoResponse {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/\(fileId)/view-info"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get file view info: \(error.localizedDescription)",
                code: "VIEW_URL_ERROR",
                suggestion: "Check the file ID and permissions"
            )
        }
    }
}