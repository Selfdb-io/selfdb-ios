import Foundation
import Core
import Auth

/// Configuration for realtime connections
public struct RealtimeConfig {
    /// WebSocket URL
    public let url: String?
    
    /// Whether to automatically reconnect on disconnection
    public let autoReconnect: Bool
    
    /// Initial reconnection interval in seconds
    public let reconnectInterval: TimeInterval
    
    /// Maximum reconnection interval in seconds
    public let maxReconnectInterval: TimeInterval
    
    /// Heartbeat interval in seconds
    public let heartbeatInterval: TimeInterval
    
    /// Maximum number of reconnection attempts
    public let maxRetries: Int
    
    /// Initial retry delay in seconds
    public let retryDelay: TimeInterval
    
    public init(
        url: String? = nil,
        autoReconnect: Bool = true,
        reconnectInterval: TimeInterval = 2.0,
        maxReconnectInterval: TimeInterval = 30.0,
        heartbeatInterval: TimeInterval = 30.0,
        maxRetries: Int = 10,
        retryDelay: TimeInterval = 1.0
    ) {
        self.url = url
        self.autoReconnect = autoReconnect
        self.reconnectInterval = reconnectInterval
        self.maxReconnectInterval = maxReconnectInterval
        self.heartbeatInterval = heartbeatInterval
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
}

/// Realtime message structure
public struct RealtimeMessage: Codable {
    public let type: String
    public let channel: String
    public let event: String
    public let payload: AnyCodable?
    
    public init(type: String, channel: String, event: String, payload: AnyCodable? = nil) {
        self.type = type
        self.channel = channel
        self.event = event
        self.payload = payload
    }
}

/// Options for subscribing to channels
public struct SubscriptionOptions {
    public let event: String?
    public let filter: [String: Any]?
    
    public init(event: String? = nil, filter: [String: Any]? = nil) {
        self.event = event
        self.filter = filter
    }
}

/// Callback for realtime events
public typealias RealtimeCallback = (Any?) -> Void

/// Connection state for realtime client
public struct ConnectionState {
    public let connected: Bool
    public let connecting: Bool
    public let reconnecting: Bool
    
    public init(connected: Bool = false, connecting: Bool = false, reconnecting: Bool = false) {
        self.connected = connected
        self.connecting = connecting
        self.reconnecting = reconnecting
    }
}

/// Subscription handle
public struct Subscription {
    public let id: String
    public let channel: String
    public let event: String?
    public let callback: RealtimeCallback
    public let unsubscribe: () -> Void
    
    internal init(
        id: String,
        channel: String,
        event: String?,
        callback: @escaping RealtimeCallback,
        unsubscribe: @escaping () -> Void
    ) {
        self.id = id
        self.channel = channel
        self.event = event
        self.callback = callback
        self.unsubscribe = unsubscribe
    }
}

/// Type-erased codable for realtime payloads
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [String: AnyCodable] {
            try container.encode(value)
        } else if let value = value as? [AnyCodable] {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }
}