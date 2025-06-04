import Foundation
#if canImport(Security)
import Security
#endif

/// Cross-platform secure storage for authentication data
/// Uses Keychain on Apple platforms, file-based storage elsewhere
public final class KeychainHelper {
    
    /// Service identifier for keychain items
    private let service: String
    
    #if !canImport(Security)
    /// File-based storage directory for non-Apple platforms
    private let storageDirectory: URL
    #endif
    
    public init(service: String = "com.selfdb.sdk") {
        self.service = service
        
        #if !canImport(Security)
        // Create storage directory for non-Apple platforms
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.storageDirectory = homeDirectory.appendingPathComponent(".selfdb")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        #endif
    }
    
    /// Store a value in the keychain
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The string value to store
    /// - Throws: KeychainError if storage fails
    public func store(key: String, value: String) throws {
        #if canImport(Security)
        try storeInKeychain(key: key, value: value)
        #else
        try storeInFile(key: key, value: value)
        #endif
    }
    
    /// Retrieve a value from the keychain
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored string value, or nil if not found
    /// - Throws: KeychainError if retrieval fails
    public func retrieve(key: String) throws -> String? {
        #if canImport(Security)
        return try retrieveFromKeychain(key: key)
        #else
        return try retrieveFromFile(key: key)
        #endif
    }
    
    /// Delete a value from the keychain
    /// - Parameter key: The key to delete
    /// - Throws: KeychainError if deletion fails
    public func delete(key: String) throws {
        #if canImport(Security)
        try deleteFromKeychain(key: key)
        #else
        try deleteFromFile(key: key)
        #endif
    }
    
    /// Clear all keychain items for this service
    /// - Throws: KeychainError if clearing fails
    public func clearAll() throws {
        #if canImport(Security)
        try clearAllFromKeychain()
        #else
        try clearAllFromFile()
        #endif
    }
    
    #if canImport(Security)
    // MARK: - Keychain Implementation (Apple Platforms)
    
    private func storeInKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // First, try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return
        }
        
        // If update failed, try to add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard addStatus == errSecSuccess else {
            throw KeychainError.storeFailed(status: Int32(addStatus))
        }
    }
    
    private func retrieveFromKeychain(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status: Int32(status))
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: Int32(status))
        }
    }
    
    private func clearAllFromKeychain() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: Int32(status))
        }
    }
    #else
    // MARK: - File-based Implementation (Non-Apple Platforms)
    
    private func fileURL(for key: String) -> URL {
        return storageDirectory.appendingPathComponent("\(service).\(key)")
    }
    
    private func storeInFile(key: String, value: String) throws {
        let url = fileURL(for: key)
        
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        do {
            try data.write(to: url, options: .atomic)
            // Set file permissions to owner-only
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
        } catch {
            throw KeychainError.storeFailed(status: -1)
        }
    }
    
    private func retrieveFromFile(key: String) throws -> String? {
        let url = fileURL(for: key)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return string
        } catch {
            throw KeychainError.retrieveFailed(status: -1)
        }
    }
    
    private func deleteFromFile(key: String) throws {
        let url = fileURL(for: key)
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw KeychainError.deleteFailed(status: -1)
            }
        }
    }
    
    private func clearAllFromFile() throws {
        let urls = try FileManager.default.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("\(service).") }
        
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    #endif
}

/// Errors that can occur during keychain operations
public enum KeychainError: Error, LocalizedError {
    case invalidData
    case storeFailed(status: Int32)
    case retrieveFailed(status: Int32)
    case deleteFailed(status: Int32)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .storeFailed(let status):
            return "Failed to store item in keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete item from keychain (status: \(status))"
        }
    }
}