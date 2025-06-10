/*
 SelfDB Swift Package Usage Examples
 
 This file contains example code showing how to use the SelfDB Swift package.
 These examples demonstrate the core functionality and patterns.
 
 To run these examples:
 1. Replace the API configuration with your actual SelfDB instance URLs and API key
 2. Call the functions from your app or test code
 3. Ensure you have proper error handling in production code
 */

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/*
 MARK: - Basic Setup
 
 Initialize the SelfDB client with your configuration
 */
func setupSelfDBClient() -> SelfDB {
    let config = SelfDBConfig(
        apiURL: URL(string: "http://localhost:8000/api/v1")!,
        storageURL: URL(string: "http://localhost:8001")!,
        apiKey: "your-anon-key-here"
    )
    
    return SelfDB(config: config)
}

/*
 MARK: - Authentication Examples
 */
func authenticationExamples() async {
    let selfDB = setupSelfDBClient()
    
    // Register a new user
    let registerResponse = await selfDB.auth.register(
        email: "user@example.com",
        password: "securePassword123"
    )
    
    if registerResponse.isSuccess {
        print("User registered successfully!")
    }
    
    // Login
    let loginResponse = await selfDB.auth.login(
        email: "user@example.com",
        password: "securePassword123"
    )
    
    if loginResponse.isSuccess {
        print("Login successful! Access token: \(selfDB.auth.accessToken ?? "")")
    }
    
    // Get current user info
    let userResponse = await selfDB.auth.getCurrentUser()
    if let user = userResponse.data {
        print("Current user: \(user.email)")
    }
}

/*
 MARK: - Database Examples
 */
func databaseExamples() async {
    let selfDB = setupSelfDBClient()
    
    // Ensure user is authenticated
    _ = await selfDB.auth.login(email: "user@example.com", password: "password")
    
    // List all tables
    let tablesResponse = await selfDB.database.listTables()
    if let tables = tablesResponse.data {
        print("Available tables: \(tables.map { $0.name })")
    }
    
    // Get table data with pagination
    let dataResponse = await selfDB.database.getTableData("users", page: 1, pageSize: 10)
    if let tableData = dataResponse.data {
        print("Found \(tableData.metadata.total_count) rows")
        print("Data columns: \(tableData.metadata.columns.map { $0.column_name })")
    }
    
    // Create a new table
    let columns = [
        CreateColumnRequest(name: "id", type: "UUID", nullable: false, primaryKey: true, defaultValue: "gen_random_uuid()"),
        CreateColumnRequest(name: "name", type: "VARCHAR(255)", nullable: false),
        CreateColumnRequest(name: "email", type: "VARCHAR(255)", nullable: false),
        CreateColumnRequest(name: "created_at", type: "TIMESTAMP", nullable: false, defaultValue: "NOW()")
    ]
    
    let createTableRequest = CreateTableRequest(
        name: "example_users",
        columns: columns,
        description: "Example users table"
    )
    
    let createResponse = await selfDB.database.createTable(createTableRequest)
    if createResponse.isSuccess {
        print("Table created successfully!")
    }
    
    // Insert data
    let insertData: [String: Any] = [
        "name": "Jane Smith",
        "email": "jane@example.com"
    ]
    
    let insertResponse = await selfDB.database.insertRow("example_users", data: insertData)
    if insertResponse.isSuccess {
        print("Data inserted successfully!")
    }
}

/*
 MARK: - Storage Examples
 */
func storageExamples() async {
    let selfDB = setupSelfDBClient()
    
    // Ensure user is authenticated
    _ = await selfDB.auth.login(email: "user@example.com", password: "password")
    
    // List buckets
    let bucketsResponse = await selfDB.storage.listBuckets()
    if let buckets = bucketsResponse.data {
        print("Available buckets: \(buckets.map { $0.name })")
    }
    
    // Create a bucket
    let createBucketRequest = CreateBucketRequest(
        name: "my-uploads",
        description: "User uploads bucket",
        isPublic: false
    )
    
    let bucketResponse = await selfDB.storage.createBucket(createBucketRequest)
    guard let bucket = bucketResponse.data else {
        print("Failed to create bucket")
        return
    }
    
    print("Created bucket: \(bucket.name)")
    
    // Upload a file
    let fileContent = "Hello, SelfDB! This is a test file.".data(using: .utf8)!
    
    let uploadRequest = InitiateUploadRequest(
        filename: "test.txt",
        contentType: "text/plain",
        size: fileContent.count,
        bucketId: bucket.id
    )
    
    let initiateResponse = await selfDB.storage.initiateUpload(uploadRequest)
    guard let uploadInfo = initiateResponse.data else {
        print("Failed to initiate upload")
        return
    }
    
    // Upload the actual file data
    let uploadResult = await selfDB.storage.uploadData(
        fileContent,
        to: uploadInfo.presigned_upload_info.upload_url,
        contentType: "text/plain"
    )
    
    if uploadResult.isSuccess {
        print("File uploaded successfully!")
        print("File ID: \(uploadInfo.file_metadata.id)")
        print("File name: \(uploadInfo.file_metadata.filename)")
        
        // Get download URL
        let downloadResponse = await selfDB.storage.getFileDownloadInfo(uploadInfo.file_metadata.id)
        if let downloadInfo = downloadResponse.data {
            print("Download URL: \(downloadInfo.download_url)")
            print("File metadata: \(downloadInfo.file_metadata.filename)")
        }
    }
    
    // List files
    let filesResponse = await selfDB.storage.listFiles()
    if let files = filesResponse.data {
        print("User has \(files.count) files")
    }
}

/*
 MARK: - Error Handling Example
 */
func errorHandlingExample() async {
    let selfDB = setupSelfDBClient()
    
    let response = await selfDB.auth.login(email: "invalid@example.com", password: "wrongpassword")
    
    if response.isSuccess {
        print("Login successful!")
    } else {
        if let error = response.error {
            switch error {
            case .httpError(let statusCode, let message):
                print("HTTP Error \(statusCode): \(message ?? "Unknown error")")
            case .networkError(let error):
                print("Network Error: \(error.localizedDescription)")
            case .authenticationRequired:
                print("Authentication is required for this operation")
            default:
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

/*
 MARK: - Complete Example
 
 A complete example showing authentication, database operations, and file upload
 */
func completeExample() async {
    let selfDB = setupSelfDBClient()
    
    // 1. Register and login
    print("1. Authenticating...")
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let testEmail = "swiftdemo_\(timestamp)@example.com"
    
    // Register new user
    let registerResponse = await selfDB.auth.register(email: testEmail, password: "password123")
    if registerResponse.isSuccess {
        print("✅ User registered successfully")
    }
    
    // Login
    let loginResponse = await selfDB.auth.login(email: testEmail, password: "password123")
    guard loginResponse.isSuccess else {
        print("❌ Authentication failed")
        return
    }
    
    print("✅ Authentication successful")
    
    // 2. Database operations
    print("\n2. Working with database...")
    
    // List tables
    let tablesResponse = await selfDB.database.listTables()
    if let tables = tablesResponse.data {
        print("✅ Found \(tables.count) tables")
    }
    
    // Create a test table
    let tableName = "swift_demo_\(timestamp)"
    let columns = [
        CreateColumnRequest(name: "id", type: "UUID", nullable: false, primaryKey: true, defaultValue: "gen_random_uuid()"),
        CreateColumnRequest(name: "name", type: "VARCHAR(255)", nullable: false),
        CreateColumnRequest(name: "description", type: "TEXT", nullable: true)
    ]
    
    let createTableRequest = CreateTableRequest(name: tableName, columns: columns, description: "Demo table from Swift SDK")
    let createTableResponse = await selfDB.database.createTable(createTableRequest)
    
    if createTableResponse.isSuccess {
        print("✅ Created table: \(tableName)")
        
        // Insert test data
        let insertData = ["name": "Demo Item", "description": "This is a test item created from Swift SDK"]
        let insertResponse = await selfDB.database.insertRow(tableName, data: insertData)
        
        if insertResponse.isSuccess {
            print("✅ Inserted test data")
            
            // Get table data
            let dataResponse = await selfDB.database.getTableData(tableName, page: 1, pageSize: 10)
            if let tableData = dataResponse.data {
                print("✅ Retrieved \(tableData.data.count) rows from table")
            }
        }
    }
    
    // 3. Storage operations
    print("\n3. Working with storage...")
    
    // List existing buckets
    let bucketsResponse = await selfDB.storage.listBuckets()
    if let buckets = bucketsResponse.data {
        print("✅ Found \(buckets.count) existing buckets")
    }
    
    // Create a test bucket
    let bucketName = "swift-demo-\(timestamp)"
    let createBucketRequest = CreateBucketRequest(
        name: bucketName,
        description: "Demo bucket from Swift SDK",
        isPublic: true
    )
    
    let bucketResponse = await selfDB.storage.createBucket(createBucketRequest)
    if let bucket = bucketResponse.data {
        print("✅ Created bucket: \(bucket.name)")
        
        // Upload a test file
        let testContent = "Hello from SelfDB Swift SDK! Created at \(Date())"
        let fileData = testContent.data(using: .utf8)!
        
        let uploadRequest = InitiateUploadRequest(
            filename: "swift-demo.txt",
            contentType: "text/plain",
            size: fileData.count,
            bucketId: bucket.id
        )
        
        let initiateResponse = await selfDB.storage.initiateUpload(uploadRequest)
        if let uploadInfo = initiateResponse.data {
            print("✅ Initiated file upload")
            
            // Upload the actual file
            let uploadResult = await selfDB.storage.uploadData(
                fileData,
                to: uploadInfo.presigned_upload_info.upload_url,
                contentType: "text/plain"
            )
            
            if uploadResult.isSuccess {
                print("✅ File uploaded successfully!")
                print("   File ID: \(uploadInfo.file_metadata.id)")
                print("   Filename: \(uploadInfo.file_metadata.filename)")
                print("   Size: \(uploadInfo.file_metadata.size) bytes")
                
                // Get download info
                let downloadResponse = await selfDB.storage.getFileDownloadInfo(uploadInfo.file_metadata.id)
                if let downloadInfo = downloadResponse.data {
                    print("✅ File download URL available")
                    print("   URL: \(downloadInfo.download_url)")
                }
            }
        }
        
        // List files in bucket
        let filesResponse = await selfDB.storage.listBucketFiles(bucket.id)
        if let files = filesResponse.data {
            print("✅ Bucket '\(bucket.name)' now has \(files.count) files")
        }
    }
    
    print("\n🎉 SelfDB Swift Package comprehensive demo completed!")
    print("This example demonstrated:")
    print("  • User registration and authentication")
    print("  • Database table creation and data operations")
    print("  • Storage bucket creation and file upload")
    print("  • Real API calls with proper error handling")
}

/*
 MARK: - Real-World Usage Pattern
 
 A practical example showing how you might use SelfDB in a real iOS app
 */
func realWorldUsageExample() async {
    let selfDB = setupSelfDBClient()
    
    // Example: User profile with avatar upload
    do {
        // 1. Authenticate user
        let loginResult = await selfDB.auth.login(email: "user@example.com", password: "password")
        guard loginResult.isSuccess else {
            print("Login failed")
            return
        }
        
        // 2. Get user profile data
        let userResponse = await selfDB.auth.getCurrentUser()
        guard let user = userResponse.data else {
            print("Could not get user data")
            return
        }
        
        print("Welcome back, \(user.email)!")
        
        // 3. Upload user avatar
        let avatarData = "fake_image_data".data(using: .utf8)! // In real app, this would be actual image data
        
        // First, create/get user's bucket
        let bucketRequest = CreateBucketRequest(
            name: "user-\(user.id)-files",
            description: "User files bucket",
            isPublic: false
        )
        
        let bucketResult = await selfDB.storage.createBucket(bucketRequest)
        let bucketId = bucketResult.data?.id ?? "existing-bucket-id"
        
        // Upload avatar
        let uploadRequest = InitiateUploadRequest(
            filename: "avatar.jpg",
            contentType: "image/jpeg",
            size: avatarData.count,
            bucketId: bucketId
        )
        
        let uploadResponse = await selfDB.storage.initiateUpload(uploadRequest)
        if let uploadInfo = uploadResponse.data {
            let uploadResult = await selfDB.storage.uploadData(
                avatarData,
                to: uploadInfo.presigned_upload_info.upload_url,
                contentType: "image/jpeg"
            )
            
            if uploadResult.isSuccess {
                print("Avatar uploaded successfully!")
                
                // Save file ID to user profile (in a real app, you'd update a user_profiles table)
                let profileData = [
                    "user_id": user.id,
                    "avatar_file_id": uploadInfo.file_metadata.id,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                let profileResult = await selfDB.database.insertRow("user_profiles", data: profileData)
                if profileResult.isSuccess {
                    print("User profile updated with avatar!")
                }
            }
        }
        
        // 4. List user's files
        let filesResponse = await selfDB.storage.listFiles()
        if let files = filesResponse.data {
            print("User has \(files.count) files stored")
            for file in files {
                print("  - \(file.filename) (\(file.size) bytes)")
            }
        }
        
    }
}