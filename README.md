# SelfDB Swift SDK

A modern, type-safe Swift SDK for [SelfDB](https://selfdb.io) - the open-source database platform. Build iOS, macOS, tvOS, watchOS, and visionOS applications with real-time data sync, authentication, file storage, and more.

## Features

- 🔐 **Authentication** - Complete auth flow with secure token management
- 📊 **Database** - Type-safe CRUD operations with your PostgreSQL database  
- 📁 **Storage** - File uploads/downloads with presigned URLs
- ⚡ **Realtime** - WebSocket subscriptions for live data updates
- 🔄 **Offline Support** - Automatic retry logic and error recovery
- 🛡️ **Type Safety** - Full Swift Codable support with compile-time checks
- 📱 **Multi-Platform** - Works on all Apple platforms

## Installation

### Swift Package Manager

Add SelfDB to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/selfdb/selfdb-swift", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

## Quick Start

### 1. Initialize the Client

```swift
import SelfDB

// Configure SelfDB with your instance details
let config = SelfDBConfig(
    baseUrl: "https://your-instance.selfdb.io",  // Your SelfDB API URL
    storageUrl: "https://storage.your-instance.selfdb.io", // Optional: defaults to port 8001
    anonKey: "your-anon-key-here"  // Get from SelfDB dashboard
)

// Create the client
let selfdb = try await createClient(config: config)
```

### 2. Authentication

```swift
// Register a new user
let user = try await selfdb.auth.register(
    credentials: RegisterRequest(
        email: "user@example.com",
        password: "securepassword"
    )
)

// Login
let response = try await selfdb.auth.login(
    credentials: LoginRequest(
        email: "user@example.com",
        password: "securepassword"
    )
)

// Get current user
if let currentUser = try await selfdb.auth.getUser() {
    print("Logged in as: \(currentUser.email)")
}

// Logout
try await selfdb.auth.logout()
```

### 3. Database Operations

```swift
// Define your data model
struct Product: Codable {
    let id: String?
    let name: String
    let price: Double
    let inStock: Bool
}

// Create
let newProduct: Product = try await selfdb.db.create(
    table: "products",
    data: [
        "name": "iPhone 15",
        "price": 999.99,
        "in_stock": true
    ]
)

// Read with filtering
let products: [Product] = try await selfdb.db.read(
    table: "products",
    options: QueryOptions(
        where: ["in_stock": AnyCodable(true)],
        orderBy: [OrderBy(column: "price", direction: .desc)],
        limit: 10
    )
)

// Update
let updated: Product = try await selfdb.db.update(
    table: "products",
    data: ["price": 899.99],
    where: ["id": newProduct.id!]
)

// Delete
let deleteResponse = try await selfdb.db.delete(
    table: "products",
    where: ["id": newProduct.id!]
)

// Pagination
let page = try await selfdb.db.paginate(
    table: "products",
    page: 1,
    limit: 20
)
print("Showing \(page.data.count) of \(page.total) products")
```

### 4. Storage

```swift
// Create a bucket
let bucket = try await selfdb.storage.createBucket(
    name: "user-uploads",
    isPublic: false
)

// Upload a file
let imageData = UIImage(named: "photo")!.jpegData(compressionQuality: 0.8)!
let uploadedFile = try await selfdb.storage.upload(
    bucket: "user-uploads",
    path: "photos/vacation.jpg",
    data: imageData,
    contentType: "image/jpeg"
)

// Download a file
let downloadedData = try await selfdb.storage.download(
    bucket: "user-uploads",
    path: "photos/vacation.jpg"
)

// Get public URL (for public buckets)
let publicUrl = try selfdb.storage.getPublicUrl(
    bucket: "public-assets",
    path: "logo.png"
)

// List files
let files = try await selfdb.storage.listFiles(
    bucket: "user-uploads",
    path: "photos/",
    limit: 100
)
```

### 5. Realtime Subscriptions

```swift
// Subscribe to table changes
let subscription = try await selfdb.realtime.subscribe(
    to: "products",
    event: .all
) { change in
    switch change.eventType {
    case .insert:
        print("New product added: \(change.new)")
    case .update:
        print("Product updated from \(change.old) to \(change.new)")
    case .delete:
        print("Product deleted: \(change.old)")
    }
}

// Subscribe with filters
let expensiveProducts = try await selfdb.realtime.subscribe(
    to: "products",
    event: .insert,
    filter: "price.gt.500"
) { change in
    print("Expensive product added: \(change.new)")
}

// Unsubscribe
try await subscription.unsubscribe()

// Check connection status
if selfdb.realtime.isConnected {
    print("Realtime connection active")
}
```

### 6. Raw SQL Queries

```swift
// Execute raw SQL
let result = try await selfdb.db.executeSql(
    query: "SELECT * FROM products WHERE price > $1 ORDER BY created_at DESC",
    params: [100.0]
)

print("Found \(result.rowCount) products")
for row in result.rows {
    print(row)
}
```

## Advanced Usage

### Error Handling

```swift
do {
    let products = try await selfdb.db.read(table: "products")
} catch let error as SelfDBError {
    print("Error: \(error.errorDescription ?? "")")
    
    if let suggestion = error.suggestion {
        print("Suggestion: \(suggestion)")
    }
    
    if error.isRetryable() {
        // Implement retry logic
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Custom Headers

```swift
let config = SelfDBConfig(
    baseUrl: "https://api.selfdb.io",
    anonKey: "your-key",
    headers: [
        "X-Custom-Header": "value",
        "X-App-Version": "1.0.0"
    ]
)
```

### Timeout Configuration

```swift
let config = SelfDBConfig(
    baseUrl: "https://api.selfdb.io",
    anonKey: "your-key",
    timeout: 30.0  // 30 seconds
)
```

## Testing

### Unit Tests

```swift
import XCTest
@testable import SelfDB

class MyAppTests: XCTestCase {
    func testDatabaseQuery() async throws {
        // Use mock configuration for tests
        let config = SelfDBConfig(
            baseUrl: "http://localhost:8000",
            anonKey: "test-key"
        )
        
        let client = try await createClient(config: config)
        
        // Your test logic here
    }
}
```

### Integration Tests

Set environment variables for integration tests:

```bash
export SELFDB_TEST_BACKEND=1
export SELFDB_BASE_URL=http://localhost:8000
export SELFDB_STORAGE_URL=http://localhost:8001
export SELFDB_ANON_KEY=your-test-key
```

## Platform Support

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- visionOS 1.0+

## Requirements

- Swift 5.9+
- Xcode 15.0+

## Security

- Tokens are securely stored in the Keychain (Apple platforms)
- Automatic token refresh on 401 errors
- All connections use HTTPS by default

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

SelfDB Swift SDK is released under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- 📚 [Documentation](https://docs.selfdb.io/swift)
- 💬 [Discord Community](https://discord.gg/selfdb)
- 🐛 [Issue Tracker](https://github.com/selfdb/selfdb-swift/issues)
- 📧 [Email Support](mailto:support@selfdb.io)

## Example App

Check out our [example app](https://github.com/selfdb/selfdb-swift-example) for a complete implementation.

```swift
// Complete example
import SwiftUI
import SelfDB

@main
struct MyApp: App {
    @StateObject private var dataStore = DataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .task {
                    await dataStore.initialize()
                }
        }
    }
}

@MainActor
class DataStore: ObservableObject {
    private var selfdb: SelfDB?
    @Published var isAuthenticated = false
    
    func initialize() async {
        do {
            let config = SelfDBConfig(
                baseUrl: "https://api.selfdb.io",
                anonKey: "your-anon-key"
            )
            
            selfdb = try await createClient(config: config)
            isAuthenticated = selfdb?.auth.isAuthenticated() ?? false
        } catch {
            print("Failed to initialize SelfDB: \(error)")
        }
    }
}
```

---

Built with ❤️ by the SelfDB team