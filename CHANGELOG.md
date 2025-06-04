# Changelog

All notable changes to the SelfDB Swift SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-12-19

### Added

#### Core Features
- 🏗️ **Package Structure**: Modular Swift Package with separate targets for Core, Auth, Database, Storage, Realtime, and main SelfDB umbrella
- 🔧 **Configuration**: `SelfDBConfig` and `Config` singleton for centralized configuration management
- 🌐 **Networking**: `HttpClient` with exponential backoff retry logic, timeout handling, and comprehensive error mapping
- 🔒 **Secure Storage**: Cross-platform secure storage using Keychain on Apple platforms and encrypted file storage on Linux
- ⚠️ **Error Handling**: Comprehensive error hierarchy with `SelfDBError`, `ApiError`, `NetworkError`, `TimeoutError`, `AuthError`, and `ValidationError`

#### Authentication Module
- 🔐 **Login/Register**: Email/password authentication with automatic session management
- 🔄 **Token Refresh**: Automatic token refresh with retry logic for expired sessions
- 👤 **User Management**: Get current user, check authentication status, secure logout
- 💾 **Session Persistence**: Secure session storage across app launches using Keychain/encrypted files
- 🔑 **Auth Headers**: Automatic authentication header management for API requests

#### Database Module
- 📊 **CRUD Operations**: Type-safe create, read, update, delete operations
- 🔍 **Query Options**: Support for filtering, ordering, limiting, and pagination
- 📄 **Pagination**: Built-in pagination with metadata (total count, page info, etc.)
- 🗃️ **Raw SQL**: Execute custom SQL queries with parameter binding
- 🎯 **Type Safety**: Full Codable support for custom models with automatic JSON encoding/decoding
- 🔎 **Find by ID**: Convenience method for single record retrieval

#### Storage Module
- 🪣 **Bucket Management**: Create, list, update, delete storage buckets
- 📁 **File Operations**: Upload, download, list, delete files with progress tracking
- 📤 **Multipart Uploads**: Support for large file uploads with proper content-type handling
- 🔗 **URL Generation**: Get secure download/view URLs for files
- 📊 **File Metadata**: Rich metadata support for uploaded files
- 🔍 **File Search**: Search and filter files within buckets

#### Realtime Module
- ⚡ **WebSocket Connections**: Native URLSessionWebSocketTask integration with fallback support
- 🔄 **Auto-Reconnect**: Intelligent reconnection with exponential backoff
- 💓 **Heartbeat**: Automatic ping/pong heartbeat to maintain connections
- 📢 **Subscriptions**: Subscribe to channels and events with flexible filtering
- 🎯 **Event Handling**: Type-safe event callbacks with payload parsing
- 🔌 **Connection State**: Real-time connection state monitoring

#### Platform Support
- 🍎 **iOS**: iOS 13.0+ support with full feature compatibility
- 🖥️ **macOS**: macOS 10.15+ support for desktop applications
- 📺 **tvOS**: tvOS 13.0+ support for Apple TV apps
- ⌚ **watchOS**: watchOS 6.0+ support for Apple Watch apps
- 🐧 **Linux**: Cross-platform support with FoundationNetworking

#### Developer Experience
- 🛠️ **Swift Concurrency**: Full async/await support throughout the SDK
- 📝 **Type Safety**: Comprehensive Codable support and generic APIs
- 🎯 **Fluent API**: Chain-able, intuitive API design matching Swift conventions
- 📚 **Documentation**: Comprehensive inline documentation for all public APIs
- 🧪 **Examples**: Console demo application demonstrating core functionality

#### Architecture & Design
- 🏛️ **Modular Design**: Clean separation of concerns with individual modules
- 🔒 **Thread Safety**: Actor-based HTTP client for safe concurrent access
- 🔄 **Retry Logic**: Configurable retry behavior with exponential backoff
- 🎛️ **Configuration**: Flexible configuration options with sensible defaults
- 🚨 **Error Recovery**: Graceful error handling with actionable suggestions

### Technical Details

#### Supported Swift Versions
- Swift 5.9+ (Package tools version)
- Swift 6.1+ compatibility

#### Dependencies
- Foundation (built-in)
- FoundationNetworking (Linux only)
- Security (Apple platforms only)

#### Build Targets
- `Core`: Configuration, networking, errors, secure storage
- `Auth`: Authentication and session management  
- `Database`: CRUD operations and SQL queries
- `Storage`: File and bucket operations
- `Realtime`: WebSocket connections and subscriptions
- `SelfDB`: Main umbrella framework

### Known Limitations
- Database queries currently support basic filtering only (full QueryBuilder coming in future release)
- File upload progress tracking not yet implemented (planned for v0.2.0)
- Functions module not included in this release (planned for v0.2.0)

### Breaking Changes
- N/A (Initial release)

### Migration Guide
- N/A (Initial release)

---

**Note**: This is the initial release of the SelfDB Swift SDK. The API is considered stable but may evolve based on community feedback and usage patterns.