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
        } else if lowercaseFilename.hasSuffix(".doc") || lowercaseFilename.hasSuffix(".docx") {
            return "application/msword"
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
    
    /// Create a new storage bucket
    /// - Parameters:
    ///   - name: Bucket name
    ///   - isPublic: Whether the bucket is public
    ///   - description: Optional bucket description
    /// - Returns: Created bucket information
    /// - Throws: SelfDB errors
    public func createBucket(
        name: String,
        isPublic: Bool = false,
        description: String? = nil
    ) async throws -> BucketInfo {
        let request = CreateBucketRequest(
            name: name,
            isPublic: isPublic,
            description: description
        )
        
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
                code: "CREATE_BUCKET_ERROR",
                suggestion: "Check bucket name and permissions"
            )
        }
    }
    
    /// List all buckets
    /// - Returns: Array of bucket information
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
                code: "LIST_BUCKETS_ERROR",
                suggestion: "Check your authentication"
            )
        }
    }
    
    /// Get bucket details
    /// - Parameter bucketId: Bucket ID
    /// - Returns: Detailed bucket information
    /// - Throws: SelfDB errors
    public func getBucket(bucketId: String) async throws -> BucketDetails {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/buckets/\(bucketId)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get bucket details: \(error.localizedDescription)",
                code: "GET_BUCKET_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Update bucket information
    /// - Parameters:
    ///   - bucketId: Bucket ID
    ///   - name: New bucket name (optional)
    ///   - isPublic: New public status (optional)
    ///   - description: New description (optional)
    /// - Returns: Updated bucket information
    /// - Throws: SelfDB errors
    public func updateBucket(
        bucketId: String,
        name: String? = nil,
        isPublic: Bool? = nil,
        description: String? = nil
    ) async throws -> BucketInfo {
        let request = UpdateBucketRequest(
            name: name,
            isPublic: isPublic,
            description: description
        )
        
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
                code: "UPDATE_BUCKET_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Delete a bucket
    /// - Parameter bucketId: Bucket ID
    /// - Throws: SelfDB errors
    public func deleteBucket(bucketId: String) async throws {
        do {
            let _: EmptyResponse = try await authClient.makeAuthenticatedRequest(
                method: .DELETE,
                path: "/api/v1/buckets/\(bucketId)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to delete bucket: \(error.localizedDescription)",
                code: "DELETE_BUCKET_ERROR",
                suggestion: "Ensure bucket is empty before deletion"
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
            // Determine content type
            let contentType = options.contentType ?? detectContentType(from: filename)
            
            // Step 1: Initiate upload to get presigned URL
            let initiateRequest = FileUploadInitiateRequest(
                filename: filename,
                contentType: contentType,
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
                contentType: contentType
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
    ///   - path: Optional path prefix
    ///   - limit: Maximum number of files to return
    /// - Returns: Array of file metadata
    /// - Throws: SelfDB errors
    public func listFiles(
        bucketId: String,
        path: String? = nil,
        limit: Int = 100
    ) async throws -> [FileMetadata] {
        var queryParams = "?limit=\(limit)"
        if let path = path {
            queryParams += "&prefix=\(path)"
        }
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/buckets/\(bucketId)/files\(queryParams)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to list files: \(error.localizedDescription)",
                code: "LIST_FILES_ERROR",
                suggestion: "Check bucket ID and permissions"
            )
        }
    }
    
    /// Initiate file upload
    /// - Parameters:
    ///   - filename: Name of the file
    ///   - contentType: MIME type of the file
    ///   - size: File size in bytes
    ///   - bucketId: Target bucket ID
    /// - Returns: Upload information including presigned URL
    /// - Throws: SelfDB errors
    public func initiateUpload(
        filename: String,
        contentType: String,
        size: Int64,
        bucketId: String
    ) async throws -> InitiateUploadResponse {
        let request = InitiateUploadRequest(
            filename: filename,
            contentType: contentType,
            size: size,
            bucketId: bucketId
        )
        
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .POST,
                path: "/api/v1/files/initiate-upload",
                body: request
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to initiate upload: \(error.localizedDescription)",
                code: "INITIATE_UPLOAD_ERROR",
                suggestion: "Check file parameters and bucket permissions"
            )
        }
    }
    
    /// Upload file data to presigned URL
    /// - Parameters:
    ///   - url: Presigned upload URL
    ///   - data: File data
    ///   - contentType: MIME type
    /// - Throws: SelfDB errors
    public func uploadToPresignedUrl(
        url: String,
        data: Data,
        contentType: String
    ) async throws {
        guard let uploadUrl = URL(string: url) else {
            throw SelfDBError(
                message: "Invalid upload URL",
                code: "INVALID_URL"
            )
        }
        
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Add API key header if it's a storage service URL
        if url.contains(config.storageUrl) {
            request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        }
        
        do {
            let session = URLSession.shared
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw SelfDBError(
                    message: "Upload failed",
                    code: "UPLOAD_FAILED"
                )
            }
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to upload file: \(error.localizedDescription)",
                code: "UPLOAD_ERROR",
                suggestion: "Check network connection and file size"
            )
        }
    }
    
    /// Convenience method to upload a file
    /// - Parameters:
    ///   - bucket: Bucket name or ID
    ///   - path: File path within bucket
    ///   - data: File data
    ///   - contentType: MIME type (auto-detected if nil)
    /// - Returns: File metadata
    /// - Throws: SelfDB errors
    public func upload(
        bucket: String,
        path: String,
        data: Data,
        contentType: String? = nil
    ) async throws -> FileMetadata {
        // Detect content type if not provided
        let mimeType = contentType ?? detectContentType(from: path)
        
        // First, get bucket ID if bucket name was provided
        let bucketId: String
        if UUID(uuidString: bucket) != nil {
            bucketId = bucket
        } else {
            // Assume it's a bucket name, need to list buckets to find ID
            let buckets = try await listBuckets()
            guard let bucketInfo = buckets.first(where: { $0.name == bucket }) else {
                throw SelfDBError(
                    message: "Bucket '\(bucket)' not found",
                    code: "BUCKET_NOT_FOUND"
                )
            }
            bucketId = bucketInfo.id
        }
        
        // Initiate upload
        let uploadInfo = try await initiateUpload(
            filename: path,
            contentType: mimeType,
            size: Int64(data.count),
            bucketId: bucketId
        )
        
        // Upload to presigned URL
        try await uploadToPresignedUrl(
            url: uploadInfo.presignedUploadInfo.uploadUrl,
            data: data,
            contentType: mimeType
        )
        
        return uploadInfo.fileMetadata
    }
    
    /// Get file download information
    /// - Parameter fileId: File ID
    /// - Returns: Download information including URL
    /// - Throws: SelfDB errors
    public func getDownloadInfo(fileId: String) async throws -> DownloadInfo {
        do {
            return try await authClient.makeAuthenticatedRequest(
                method: .GET,
                path: "/api/v1/files/\(fileId)/download-info"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get download info: \(error.localizedDescription)",
                code: "DOWNLOAD_INFO_ERROR",
                suggestion: "Check file ID and permissions"
            )
        }
    }
    
    /// Download file data
    /// - Parameters:
    ///   - bucket: Bucket name
    ///   - path: File path within bucket
    /// - Returns: File data
    /// - Throws: SelfDB errors
    public func download(bucket: String, path: String) async throws -> Data {
        // Get file by path
        let bucketId: String
        if UUID(uuidString: bucket) != nil {
            bucketId = bucket
        } else {
            let buckets = try await listBuckets()
            guard let bucketInfo = buckets.first(where: { $0.name == bucket }) else {
                throw SelfDBError(
                    message: "Bucket '\(bucket)' not found",
                    code: "BUCKET_NOT_FOUND"
                )
            }
            bucketId = bucketInfo.id
        }
        
        // List files to find the one with matching path
        let files = try await listFiles(bucketId: bucketId)
        guard let file = files.first(where: { $0.filename == path || $0.objectName == path }) else {
            throw SelfDBError(
                message: "File '\(path)' not found in bucket '\(bucket)'",
                code: "FILE_NOT_FOUND"
            )
        }
        
        // Get download URL
        let downloadInfo = try await getDownloadInfo(fileId: file.id)
        
        // Download from URL
        guard let url = URL(string: downloadInfo.downloadUrl) else {
            throw SelfDBError(
                message: "Invalid download URL",
                code: "INVALID_URL"
            )
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw SelfDBError(
                message: "Download failed",
                code: "DOWNLOAD_FAILED"
            )
        }
        
        return data
    }
    
    /// Delete a file
    /// - Parameter fileId: File ID
    /// - Throws: SelfDB errors
    public func deleteFile(fileId: String) async throws {
        do {
            let _: EmptyResponse = try await authClient.makeAuthenticatedRequest(
                method: .DELETE,
                path: "/api/v1/files/\(fileId)"
            )
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to delete file: \(error.localizedDescription)",
                code: "DELETE_FILE_ERROR",
                suggestion: "Check file ID and permissions"
            )
        }
    }
    
    /// Get file view information
    /// - Parameter fileId: File ID
    /// - Returns: File view information including URL
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
                code: "VIEW_INFO_ERROR",
                suggestion: "Check file ID and permissions"
            )
        }
    }
    
    /// Get public file view information (for files in public buckets)
    /// - Parameter fileId: File ID
    /// - Returns: File view information including URL
    /// - Throws: SelfDB errors
    public func getPublicFileViewInfo(fileId: String) async throws -> FileViewInfoResponse {
        do {
            // For public endpoints, we still need to make a request but without auth
            // Create a URL directly and make the request
            guard let url = URL(string: "\(config.baseUrl)/api/v1/files/public/\(fileId)/view-info") else {
                throw SelfDBError(
                    message: "Invalid URL for public file view info",
                    code: "INVALID_URL"
                )
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SelfDBError(
                    message: "Invalid response",
                    code: "INVALID_RESPONSE"
                )
            }
            
            if httpResponse.statusCode == 404 {
                throw SelfDBError(
                    message: "File not found or not in a public bucket",
                    code: "FILE_NOT_FOUND",
                    suggestion: "Ensure the file exists and is in a public bucket"
                )
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw SelfDBError(
                    message: "Failed to get public file view info: \(errorMessage) (HTTP \(httpResponse.statusCode))",
                    code: "PUBLIC_VIEW_INFO_ERROR"
                )
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(FileViewInfoResponse.self, from: data)
            
        } catch {
            if error is SelfDBError { throw error }
            throw SelfDBError(
                message: "Failed to get public file view info: \(error.localizedDescription)",
                code: "PUBLIC_VIEW_INFO_ERROR",
                suggestion: "Ensure the file is in a public bucket"
            )
        }
    }
}