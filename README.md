# 🚀 SelfDB Swift SDK

A first-class Swift SDK for SelfDB - a self-hosted alternative to Supabase. Build powerful iOS, macOS, tvOS, and watchOS applications with real-time features, authentication, database operations, and file storage.

## ✨ Features

- 🔐 **Authentication** - Login, register, logout, token refresh with secure session management
- 📊 **Database** - CRUD operations with type-safe queries and pagination
- 📁 **Storage** - File upload/download with progress tracking and bucket management  
- ⚡ **Realtime** - WebSocket connections with auto-reconnect and event subscriptions
- 🔄 **Cross-platform** - Supports iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+
- 🛡️ **Type Safety** - Full Swift type safety with Codable support
- 🔁 **Async/Await** - Modern Swift concurrency for all operations
- 🔒 **Secure Storage** - Keychain integration on Apple platforms, secure file storage elsewhere

## 📦 Installation

### Swift Package Manager

Add SelfDB to your project through Xcode:

1. File → Add Package Dependencies
2. Enter repository URL: `https://github.com/rodgersmag/SDK`
3. Select the SelfDB package

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rodgersmag/SDK", from: "0.1.0")
]
```

## 🚀 Quick Start

```swift
import SelfDB

// Initialize the client
let config = SelfDBConfig(
    baseUrl: "http://localhost:8000",
    storageUrl: "http://localhost:8001", // Optional, defaults to baseUrl with port 8001
    anonKey: "your-anonymous-key"
)

let selfdb = try await createClient(config: config)

// Authenticate
let loginResponse = try await selfdb.auth.login(credentials: LoginRequest(
    email: "user@example.com",
    password: "password123"
))

// Database operations
let users: [User] = try await selfdb.db.read(table: "users")
let newUser: User = try await selfdb.db.create(table: "users", data: [
    "email": "new@example.com",
    "name": "New User"
])

// Storage operations
let buckets = try await selfdb.storage.listBuckets()
let uploadResponse = try await selfdb.storage.upload(
    bucket: "my-bucket",
    file: fileData,
    filename: "document.pdf"
)

// Realtime subscriptions
try await selfdb.realtime.connect()
let subscription = try selfdb.realtime.subscribe("users") { payload in
    print("User updated: \(payload)")
}
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in your project:

```bash
SELFDB_URL=http://localhost:8000
SELFDB_STORAGE_URL=http://localhost:8001
SELFDB_ANON_KEY=your_anon_key_here
```

### SelfDBConfig Options

```swift
let config = SelfDBConfig(
    baseUrl: "http://localhost:8000",     // Required: Your SelfDB backend URL
    storageUrl: "http://localhost:8001",  // Optional: Storage service URL
    anonKey: "your-anon-key",             // Required: Anonymous access key
    headers: ["Custom": "Header"],        // Optional: Additional headers
    timeout: 10.0                         // Optional: Request timeout in seconds
)
```

## 🔐 Authentication

### Login
```swift
let loginResponse = try await selfdb.auth.login(credentials: LoginRequest(
    email: "user@example.com",
    password: "password123"
))
print("Welcome, \(loginResponse.user.email)!")
```

### Register
```swift
let registerResponse = try await selfdb.auth.register(credentials: RegisterRequest(
    email: "new@example.com",
    password: "securepassword"
))
```

### Session Management
```swift
// Check authentication status
if selfdb.auth.isAuthenticated() {
    let user = selfdb.auth.getCurrentUser()
    print("Logged in as: \(user?.email ?? "Unknown")")
}

// Get fresh user data
let currentUser = try await selfdb.auth.getUser()

// Logout
try await selfdb.auth.logout()
```

## 📊 Database Operations

### Basic CRUD
```swift
// Create
let newRecord: MyModel = try await selfdb.db.create(table: "items", data: [
    "name": "Item Name",
    "price": 29.99,
    "active": true
])

// Read with options
let items: [MyModel] = try await selfdb.db.read(
    table: "items",
    options: QueryOptions(
        where: ["active": AnyCodable(true)],
        orderBy: [OrderBy(column: "created_at", direction: .desc)],
        limit: 10
    )
)

// Update
let updated: MyModel = try await selfdb.db.update(
    table: "items",
    data: ["name": "Updated Name"],
    where: ["id": itemId]
)

// Delete
try await selfdb.db.delete(table: "items", where: ["id": itemId])
```

### Pagination
```swift
let page = try await selfdb.db.paginate<MyModel>(
    table: "items",
    page: 1,
    limit: 20,
    options: QueryOptions(orderBy: [OrderBy(column: "name")])
)

print("Page \(page.page) of \(page.total) items")
for item in page.data {
    print("- \(item.name)")
}
```

### Raw SQL
```swift
let result = try await selfdb.db.executeSql(
    query: "SELECT COUNT(*) as count FROM users WHERE active = ?",
    params: [true]
)
```

## 📁 Storage Operations

### Bucket Management
```swift
// List buckets
let buckets = try await selfdb.storage.listBuckets()

// Create bucket
let bucket = try await selfdb.storage.createBucket(CreateBucketRequest(
    name: "my-bucket",
    isPublic: true,
    description: "My file bucket"
))

// Update bucket
let updated = try await selfdb.storage.updateBucket(
    bucketId: bucket.id,
    UpdateBucketRequest(description: "Updated description")
)
```

### File Operations
```swift
// Upload file
let fileData = "Hello, World!".data(using: .utf8)!
let response = try await selfdb.storage.upload(
    bucket: "my-bucket",
    file: fileData,
    filename: "hello.txt",
    options: UploadFileOptions(contentType: "text/plain")
)

// List files
let files = try await selfdb.storage.listFiles(
    bucketId: bucket.id,
    options: FileListOptions(limit: 50)
)

// Get download URL
let downloadUrl = try await selfdb.storage.getUrl(
    bucket: "my-bucket",
    fileId: response.file.id
)

// Delete file
try await selfdb.storage.deleteFile(fileId: response.file.id)
```

## ⚡ Realtime Features

### Connect and Subscribe
```swift
// Connect to realtime service
try await selfdb.realtime.connect()

// Subscribe to table changes
let subscription = try selfdb.realtime.subscribe("users") { payload in
    if let userData = payload as? [String: Any] {
        print("User changed: \(userData)")
    }
}

// Subscribe to specific events
let insertSub = try selfdb.realtime.subscribe(
    "users",
    callback: { payload in
        print("New user: \(payload)")
    },
    options: SubscriptionOptions(event: "INSERT")
)
```

### Connection Management
```swift
// Check connection status
if selfdb.realtime.isConnected() {
    print("Connected to realtime service")
}

// Get connection state
let state = selfdb.realtime.getConnectionState()
print("Connected: \(state.connected), Connecting: \(state.connecting)")

// Disconnect
selfdb.realtime.disconnect()
```

## 🛡️ Error Handling

```swift
do {
    let user = try await selfdb.auth.login(credentials: credentials)
} catch let error as AuthError {
    print("Authentication failed: \(error.localizedDescription)")
    if let suggestion = error.suggestion {
        print("Suggestion: \(suggestion)")
    }
} catch let error as NetworkError {
    print("Network error: \(error.localizedDescription)")
    if error.isRetryable() {
        // Retry the operation
    }
} catch let error as SelfDBError {
    print("SelfDB error: \(error.localizedDescription)")
    print("Code: \(error.code)")
} catch {
    print("Unexpected error: \(error)")
}
```

## 🔧 Custom Models

Define your own Codable models:

```swift
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let isActive: Bool
    let createdAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, email, name
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// Use with type safety
let users: [User] = try await selfdb.db.read(table: "users")
let newUser: User = try await selfdb.db.create(table: "users", data: [
    "email": "user@example.com",
    "name": "John Doe",
    "is_active": true
])
```

## 📱 Platform Support

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 13.0           |
| macOS    | 10.15          |
| tvOS     | 13.0           |
| watchOS  | 6.0            |

## 🏗️ Architecture

The SDK is built with a modular architecture:

- **Core**: Configuration, networking, error handling, secure storage
- **Auth**: Authentication and session management
- **Database**: CRUD operations and SQL queries
- **Storage**: File and bucket operations
- **Realtime**: WebSocket connections and subscriptions
- **SelfDB**: Main facade providing unified access

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support


- 🐛 [Issue Tracker](https://github.com/rodgersmag/SDK/issues)
- 📧 [Email Support](mailto:contact@selfdb.io)

---

Built with ❤️ by the SelfDB team