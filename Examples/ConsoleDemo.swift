import Foundation
import SelfDB
import Core

/// Console demo for SelfDB Swift SDK
/// Mirrors the functionality of basic-usage.js from the JavaScript SDK
@main
struct SelfDBConsoleDemo {
    static func main() async {
        do {
            // Initialize the SelfDB client
            print("🚀 Initializing SelfDB client...")
            
            let config = SelfDBConfig(
                baseUrl: "http://localhost:8000", // Your SelfDB backend URL
                storageUrl: "http://localhost:8001", // Your SelfDB storage service URL  
                anonKey: "your-anonymous-key" // Required: for API access (get from your .env file)
            )
            
            let selfdb = try await createClient(config: config)
            print("✅ SelfDB client initialized")
            
            // 1. Authentication
            print("\n🔐 Authenticating...")
            let loginResponse = try await selfdb.auth.login(credentials: LoginRequest(
                email: "admin@example.com",
                password: "adminpassword"
            ))
            print("✅ Logged in as: \(loginResponse.user.email)")
            
            // 2. Database Operations
            print("\n📊 Database Operations...")
            
            // Read users
            let users: [User] = try await selfdb.db.read(
                table: "users",
                options: QueryOptions(
                    orderBy: [OrderBy(column: "created_at", direction: .desc)],
                    limit: 5
                )
            )
            print("✅ Found \(users.count) users")
            
            // Create a new user if we have less than 10
            if users.count < 10 {
                let timestamp = Int(Date().timeIntervalSince1970)
                let newUserData: [String: Any] = [
                    "email": "user\(timestamp)@example.com",
                    "password": "password123",
                    "is_active": true
                ]
                
                let newUser: User = try await selfdb.db.create(table: "users", data: newUserData)
                print("✅ Created user: \(newUser.email)")
            }
            
            // 3. Storage Operations
            print("\n📁 Storage Operations...")
            
            // List buckets
            let buckets = try await selfdb.storage.listBuckets()
            print("✅ Found \(buckets.count) buckets")
            
            // Create a bucket if none exist
            if buckets.isEmpty {
                let bucketRequest = CreateBucketRequest(
                    name: "test-bucket",
                    isPublic: true,
                    description: "Test bucket for SDK demo"
                )
                
                let bucket = try await selfdb.storage.createBucket(bucketRequest)
                print("✅ Created bucket: \(bucket.name)")
            }
            
            // 4. Realtime Connection
            print("\n⚡ Realtime Operations...")
            
            try await selfdb.realtime.connect()
            print("✅ Connected to realtime service")
            
            // Subscribe to user changes
            let subscription = try selfdb.realtime.subscribe("users") { payload in
                print("🔔 Realtime update: \(payload ?? "nil")")
            }
            print("✅ Subscribed to user changes")
            
            // 5. Raw SQL Query (if supported)
            print("\n🗃️ Raw SQL Query...")
            
            do {
                let result = try await selfdb.db.executeSql(
                    query: "SELECT COUNT(*) as user_count FROM users WHERE is_active = ?",
                    params: [true]
                )
                
                if let firstRow = result.rows.first, let count = firstRow.first {
                    print("✅ Active users count: \(count.value)")
                }
            } catch {
                print("⚠️ SQL query failed: \(error.localizedDescription)")
            }
            
            // Clean up
            subscription.unsubscribe()
            selfdb.realtime.disconnect()
            
            print("\n🎉 Demo completed successfully!")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            if let selfdbError = error as? SelfDBError {
                if let suggestion = selfdbError.suggestion {
                    print("💡 Suggestion: \(suggestion)")
                }
            }
        }
    }
}

/// Simple User model for demo
struct User: Codable {
    let id: String
    let email: String
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}