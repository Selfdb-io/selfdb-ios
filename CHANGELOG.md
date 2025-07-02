# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2025-07-02

### Added
- `deleteAccount()` method to `AuthClient` class for user account deletion
- Authentication required validation for delete account functionality
- Automatic sign out after successful account deletion
- Unit test for delete account without authentication
- Integration test for complete delete account flow

### Changed
- Enhanced authentication flow to support account deletion endpoint

## [0.0.1] - 2024-12-XX

### Added
- Initial release of SelfDB Swift package
- Authentication client with login, register, and token refresh
- Database client for CRUD operations
- Storage client for file operations
- Realtime client for WebSocket connections
- Comprehensive test suite with integration tests
- Full documentation and README