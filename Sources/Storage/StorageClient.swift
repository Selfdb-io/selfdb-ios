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
    
    /// Detect content type from filename extension
    private func detectContentType(from filename: String) -> String {
        let lowercaseFilename = filename.lowercased()
        
        // Image types
        if lowercaseFilename.hasSuffix(".jpg") || lowercaseFilename.hasSuffix(".jpeg") {
            return "image/jpeg"
        } else if lowercaseFilename.hasSuffix(".png") {
            return "image/png"
        } else if lowercaseFilename.hasSuffix(".gif") {
            return "image/gif"
        } else if lowercaseFilename.hasSuffix(".webp") {
            return "image/webp"
        }
        // Video types
        else if lowercaseFilename.hasSuffix(".mp4") {
            return "video/mp4"
        } else if lowercaseFilename.hasSuffix(".mov") {
            return "video/quicktime"
        } else if lowercaseFilename.hasSuffix(".avi") {
            return "video/x-msvideo"
        }
        // Audio types
        else if lowercaseFilename.hasSuffix(".mp3") {
            return "audio/mpeg"
        } else if lowercaseFilename.hasSuffix(".wav") {
            return "audio/wav"
        }
        // Document types
        else if lowercaseFilename.hasSuffix(".pdf") {
            return "application/pdf"
        } else if lowercaseFilename.hasSuffix(".txt") {
            return "text/plain"
        } else if lowercaseFilename.hasSuffix(".json") {
            return "application/json"
        }
        // Default
        else {
            return "application/octet-stream"
        }
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
            // Determine content type if not provided
            let contentType = options.contentType ?? detectContentType(from: filename)
            
            print("🔄 Starting upload for \(filename) to bucket \(bucketName)")
            print("   - Bucket ID: \(bucket.id)")
            print("   - Content Type: \(contentType)")
            print("   - File Size: \(fileData.count) bytes")
            
            // Step 1: Initiate upload via backend API (matches JS SDK exactly)
            let initiateRequest = FileUploadInitiateRequest(
                filename: filename,
                contentType: contentType,
                size: fileData.count,
                bucketId: bucket.id
            )
            
            print("🔄 Step 1: Calling initiate-upload...")
            
            let response: FileUploadInitiateResponse = try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/files/initiate-upload",
                body: initiateRequest
            )
            
            print("✅ Step 1 completed: Got presigned URL")
            print("   - Upload URL: \(response.presignedUploadInfo.uploadUrl)")
            print("   - Upload Method: \(response.presignedUploadInfo.uploadMethod)")
            print("   - File ID: \(response.fileMetadata.id)")
            
            // Step 2: Upload directly to storage service using presigned URL (matches JS SDK fetch)
            print("🔄 Step 2: Uploading to presigned URL...")
            try await uploadToPresignedUrlDirectly(
                uploadUrl: response.presignedUploadInfo.uploadUrl,
                uploadMethod: response.presignedUploadInfo.uploadMethod,
                fileData: fileData,
                contentType: contentType
            )
            
            print("✅ Step 2 completed: File uploaded successfully")
            
            // Return the file metadata in the expected format (matches JS SDK: { file: file_metadata })
            return FileUploadResponse(file: response.fileMetadata, uploadUrl: nil)
            
        } catch let selfDBError as SelfDBError {
            print("❌ SelfDB Error during upload: \(selfDBError.errorDescription ?? "Unknown error")")
            print("   - Code: \(selfDBError.code)")
            print("   - Suggestion: \(selfDBError.suggestion ?? "N/A")")
            throw selfDBError
        } catch {
            print("❌ Unexpected error during upload: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
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
    
    /// Upload file data directly to presigned URL (matches JS SDK fetch exactly)
    private func uploadToPresignedUrlDirectly(
        uploadUrl: String,
        uploadMethod: String,
        fileData: Data,
        contentType: String
    ) async throws {
        guard let url = URL(string: uploadUrl) else {
            print("❌ Invalid presigned URL: \(uploadUrl)")
            throw SelfDBError(
                message: "Invalid presigned URL",
                code: "INVALID_URL",
                suggestion: "Contact support if this persists"
            )
        }
        
        print("🔄 Uploading to presigned URL: \(uploadUrl)")
        print("   - Method: \(uploadMethod.uppercased())")
        print("   - Content-Type: \(contentType)")
        print("   - Data size: \(fileData.count) bytes")
        
        // Create request exactly like JS SDK fetch
        var request = URLRequest(url: url)
        request.httpMethod = uploadMethod.uppercased()
        request.httpBody = fileData
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        do {
            let (responseData, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type received")
                throw SelfDBError(
                    message: "Invalid response received",
                    code: "INVALID_RESPONSE",
                    suggestion: "Check network connection"
                )
            }
            
            print("📡 Presigned upload response: \(httpResponse.statusCode)")
            
            if let responseString = String(data: responseData, encoding: .utf8), !responseString.isEmpty {
                print("   - Response body: \(responseString)")
            }
            
            // Check for success (matches JS SDK: if (!response.ok))
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                print("❌ Presigned upload failed with status \(httpResponse.statusCode): \(errorMessage)")
                throw SelfDBError(
                    message: "Upload failed: \(httpResponse.statusCode) \(errorMessage)",
                    code: "UPLOAD_FAILED",
                    suggestion: "Check file format and size limits"
                )
            }
            
            print("✅ Presigned upload completed successfully")
            
        } catch {
            print("❌ Network error during presigned upload: \(error)")
            if error is SelfDBError {
                throw error
            }
            throw SelfDBError(
                message: "Network error: \(error.localizedDescription)",
                code: "NETWORK_ERROR",
                suggestion: "Check your internet connection"
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
            print("❌ Invalid presigned URL: \(presignedInfo.uploadUrl)")
            throw SelfDBError(
                message: "Invalid presigned URL",
                code: "INVALID_URL",
                suggestion: "Contact support if this persists"
            )
        }
        
        print("🔄 Uploading to presigned URL: \(presignedInfo.uploadUrl)")
        print("   - Method: \(presignedInfo.uploadMethod)")
        print("   - Content-Type: \(contentType ?? "none")")
        print("   - Data size: \(fileData.count) bytes")
        
        var request = URLRequest(url: url)
        request.httpMethod = presignedInfo.uploadMethod.uppercased()
        request.httpBody = fileData
        
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        let session = URLSession.shared
        
        do {
            let (responseData, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type received")
                throw NetworkError("Invalid response received")
            }
            
            print("📡 Presigned upload response: \(httpResponse.statusCode)")
            
            if let responseString = String(data: responseData, encoding: .utf8), !responseString.isEmpty {
                print("   - Response body: \(responseString)")
            }
            
            if httpResponse.statusCode >= 400 {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                print("❌ Presigned upload failed with status \(httpResponse.statusCode): \(errorMessage)")
                throw ApiError("Presigned upload failed: \(errorMessage)", status: httpResponse.statusCode)
            }
            
            print("✅ Presigned upload completed successfully")
            
        } catch {
            print("❌ Network error during presigned upload: \(error)")
            throw error
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