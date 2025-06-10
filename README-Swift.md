# SelfDB Swift Package

A Swift Package for SelfDB that provides native iOS/macOS support for all SelfDB services including Authentication, Database, Storage, and Realtime.

## Features

- **Authentication**: User registration, login, token refresh, and user management
- **Database**: Table operations, data CRUD, and query building
- **Storage**: Bucket and file management with direct upload/download
- **Type-Safe**: Full Swift Codable support for all API types
- **Async/Await**: Modern Swift concurrency patterns
- **Multi-Platform**: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

## Installation

### Swift Package Manager

Add the SelfDB package to your project by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Selfdb-io/selfdb-ios", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/Selfdb-io/selfdb-ios`
3. Select the version and add to your target

## Quick Start

### 1. Initialize the Client

```swift
import SelfDB

let config = SelfDBConfig(
    apiURL: "http://localhost:8000/api/v1",
    storageURL: "localhost:8001", 
    apiKey: "your-anon-key"
)

let selfDB = SelfDB(config: config)
```

### 2. Authentication

```swift
// Register a new user
let registerResponse = await selfDB.auth.register(
    email: "user@example.com",
    password: "password123"
)

// Login
let loginResponse = await selfDB.auth.login(
    email: "user@example.com", 
    password: "password123"
)

// Get current user
let userResponse = await selfDB.auth.getCurrentUser()
```

### 3. Database Operations

```swift
// List tables
let tablesResponse = await selfDB.database.listTables()

// Get table data
let dataResponse = await selfDB.database.getTableData("users", page: 1, pageSize: 10)

// Create a table
let columns = [
    CreateColumnRequest(name: "id", type: "UUID", nullable: false, primaryKey: true, defaultValue: "gen_random_uuid()"),
    CreateColumnRequest(name: "name", type: "VARCHAR(255)", nullable: false)
]
let createTableRequest = CreateTableRequest(name: "products", columns: columns)
let tableResponse = await selfDB.database.createTable(createTableRequest)

// Insert data
let insertData = ["name": "Product 1", "price": 29.99]
let insertResponse = await selfDB.database.insertRow("products", data: insertData)
```

### 4. Storage Operations

```swift
// List buckets
let bucketsResponse = await selfDB.storage.listBuckets()

// Create a bucket
let createBucketRequest = CreateBucketRequest(
    name: "my-bucket",
    description: "My test bucket",
    isPublic: true
)
let bucketResponse = await selfDB.storage.createBucket(createBucketRequest)

// Upload a file
let fileData = "Hello, SelfDB!".data(using: .utf8)!
let uploadRequest = InitiateUploadRequest(
    filename: "test.txt",
    contentType: "text/plain",
    size: fileData.count,
    bucketId: bucket.id
)

let initiateResponse = await selfDB.storage.initiateUpload(uploadRequest)
if let uploadInfo = initiateResponse.data {
    let uploadResult = await selfDB.storage.uploadData(
        fileData,
        to: uploadInfo.presigned_upload_info.upload_url,
        contentType: "text/plain"
    )
    
    // Get file download info
    if uploadResult.isSuccess {
        let downloadResponse = await selfDB.storage.getFileDownloadInfo(uploadInfo.file_metadata.id)
        if let downloadInfo = downloadResponse.data {
            print("Download URL: \(downloadInfo.download_url)")
        }
    }
}

// List files
let filesResponse = await selfDB.storage.listFiles()
```

## Error Handling

All methods return a `SelfDBResponse<T>` that contains the result and any errors:

```swift
let response = await selfDB.auth.login(email: email, password: password)

if response.isSuccess {
    print("Login successful: \(response.data!)")
} else if let error = response.error {
    print("Login failed: \(error.localizedDescription)")
}
```

## Response Structures

### File Upload Response

When initiating a file upload, the response contains both file metadata and upload information:

```swift
let uploadResponse = await selfDB.storage.initiateUpload(request)
if let uploadInfo = uploadResponse.data {
    // File metadata
    let fileId = uploadInfo.file_metadata.id
    let filename = uploadInfo.file_metadata.filename
    let size = uploadInfo.file_metadata.size
    
    // Upload information
    let uploadURL = uploadInfo.presigned_upload_info.upload_url
    let method = uploadInfo.presigned_upload_info.upload_method
    
    // Use the upload URL to upload the file
    let uploadResult = await selfDB.storage.uploadData(
        fileData,
        to: uploadURL,
        contentType: "text/plain"
    )
}
```

### File Download Response

File download information includes both metadata and the download URL:

```swift
let downloadResponse = await selfDB.storage.getFileDownloadInfo(fileId)
if let downloadInfo = downloadResponse.data {
    let downloadURL = downloadInfo.download_url
    let fileMetadata = downloadInfo.file_metadata
    print("Download \(fileMetadata.filename) from: \(downloadURL)")
}
```

## Configuration

The `SelfDBConfig` requires three parameters:

- `apiURL`: Your SelfDB backend API URL (e.g., "https://api.selfdb.io/api/v1")
- `storageURL`: Your SelfDB storage service URL (e.g., "https://storage.selfdb.io")
- `apiKey`: Anonymous API key for public access

## API Reference

### SelfDB Client

The main `SelfDB` class provides access to all services:

- `auth: AuthClient` - Authentication operations
- `database: DatabaseClient` - Database operations  
- `storage: StorageClient` - Storage operations

### Authentication (`selfDB.auth`)

- `register(email:password:)` - Register a new user
- `login(email:password:)` - Login with email/password
- `refreshToken()` - Refresh the access token
- `getCurrentUser()` - Get current user information
- `signOut()` - Sign out the current user

### Database (`selfDB.database`)

- `listTables()` - List all tables
- `getTable(_:)` - Get table details
- `getTableData(_:page:pageSize:)` - Get paginated table data
- `createTable(_:)` - Create a new table
- `updateTable(_:_:)` - Update table description
- `deleteTable(_:)` - Delete a table
- `insertRow(_:data:)` - Insert data into table
- `updateRow(_:rowId:data:)` - Update a row
- `deleteRow(_:rowId:)` - Delete a row

### Storage (`selfDB.storage`)

- `listBuckets()` - List all buckets
- `createBucket(_:)` - Create a new bucket
- `getBucket(_:)` - Get bucket details
- `updateBucket(_:_:)` - Update bucket
- `listBucketFiles(_:)` - List files in bucket
- `listFiles()` - List user files
- `initiateUpload(_:)` - Initiate file upload
- `uploadData(_:to:contentType:)` - Upload file data
- `getFileDownloadInfo(_:)` - Get file download URL
- `getFileViewInfo(_:)` - Get file view URL
- `deleteFile(_:)` - Delete a file

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

## License

This Swift package follows the same licensing as the main SelfDB project. See the main repository for license details.

## Contributing

Contributions are welcome! Please see the main SelfDB repository for contribution guidelines.