import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Core
import Auth

/// Realtime client for SelfDB WebSocket connections
public final class RealtimeClient: NSObject {
    private let authClient: AuthClient
    private let config: RealtimeConfig
    private var webSocketTask: URLSessionWebSocketTask?
    private var connectionState = ConnectionState()
    private var subscriptions: [String: (String, String?, RealtimeCallback)] = [:]
    private var retryCount = 0
    private var heartbeatTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    
    public init(authClient: AuthClient, config: RealtimeConfig = RealtimeConfig()) throws {
        self.authClient = authClient
        
        // Build WebSocket URL
        let baseConfig = try Config.getInstance()
        let wsUrl = config.url ?? baseConfig.baseUrl.replacingOccurrences(of: "http", with: "ws") + "/api/v1/realtime/ws"
        
        self.config = RealtimeConfig(
            url: wsUrl,
            autoReconnect: config.autoReconnect,
            maxRetries: config.maxRetries,
            retryDelay: config.retryDelay
        )
        
        super.init()
    }
    
    /// Connect to the realtime service
    /// - Throws: SelfDB errors
    public func connect() async throws {
        guard !connectionState.connected && !connectionState.connecting else {
            return
        }
        
        self.connectionState = ConnectionState(connecting: true)
        
        do {
            try await performConnection()
        } catch {
            self.connectionState = ConnectionState()
            throw error
        }
    }
    
    /// Disconnect from the realtime service
    public func disconnect() {
        heartbeatTask?.cancel()
        reconnectTask?.cancel()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        subscriptions.removeAll()
        self.connectionState = ConnectionState()
    }
    
    /// Subscribe to a channel
    /// - Parameters:
    ///   - channel: Channel name
    ///   - callback: Callback for received messages
    ///   - options: Subscription options
    /// - Returns: Subscription handle
    /// - Throws: SelfDB errors
    @discardableResult
    public func subscribe(
        _ channel: String,
        callback: @escaping RealtimeCallback,
        options: SubscriptionOptions = SubscriptionOptions()
    ) throws -> Subscription {
        let subscriptionId = UUID().uuidString
        
        subscriptions[subscriptionId] = (channel, options.event, callback)
        
        // Send subscription message if connected
        if connectionState.connected {
            let message = RealtimeMessage(
                type: "subscribe",
                channel: channel,
                event: options.event ?? "*"
            )
            
            Task {
                try? await sendMessage(message)
            }
        }
        
        return Subscription(
            id: subscriptionId,
            channel: channel,
            event: options.event,
            callback: callback,
            unsubscribe: { [weak self] in
                self?.unsubscribe(subscriptionId: subscriptionId)
            }
        )
    }
    
    /// Get current connection state
    /// - Returns: Connection state
    public func getConnectionState() -> ConnectionState {
        return connectionState
    }
    
    /// Check if connected
    /// - Returns: True if connected
    public func isConnected() -> Bool {
        return connectionState.connected
    }
    
    // MARK: - Private Methods
    
    private func performConnection() async throws {
        guard let url = URL(string: config.url!) else {
            throw SelfDBError(
                message: "Invalid WebSocket URL",
                code: "INVALID_URL"
            )
        }
        
        var request = URLRequest(url: url)
        
        // Add auth headers
        let headers = authClient.getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: request)
        
        webSocketTask?.resume()
        
        // Start receiving messages
        startReceiving()
        
        // Wait for connection to be established
        try await waitForConnection()
        
        self.connectionState = ConnectionState(connected: true)
        self.retryCount = 0
        
        // Start heartbeat
        startHeartbeat()
        
        // Resubscribe to existing subscriptions
        await resubscribeAll()
    }
    
    private func waitForConnection() async throws {
        // Simple wait for connection - in a real implementation you might want to
        // wait for a specific handshake message
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    private func startReceiving() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving
                self.startReceiving()
                
            case .failure(let error):
                self.handleDisconnection(error: error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        Task {
            do {
                let data: Data
                
                switch message {
                case .string(let text):
                    data = text.data(using: .utf8) ?? Data()
                case .data(let messageData):
                    data = messageData
                @unknown default:
                    return
                }
                
                let decoder = JSONDecoder()
                let realtimeMessage = try decoder.decode(RealtimeMessage.self, from: data)
                
                // Handle different message types
                switch realtimeMessage.type {
                case "ping":
                    // Respond to ping
                    let pong = RealtimeMessage(type: "pong", channel: "", event: "")
                    try await sendMessage(pong)
                    
                case "pong":
                    // Heartbeat response - ignore
                    break
                    
                default:
                    // Broadcast to subscribers
                    await broadcastToSubscribers(realtimeMessage)
                }
                
            } catch {
                // Failed to parse message - ignore for now
            }
        }
    }
    
    private func broadcastToSubscribers(_ message: RealtimeMessage) async {
        for (_, subscription) in subscriptions {
            let (channel, event, callback) = subscription
            
            // Check if message matches subscription
            if channel == message.channel {
                if let requiredEvent = event, requiredEvent != "*" {
                    if requiredEvent == message.event {
                        callback(message.payload?.value)
                    }
                } else {
                    callback(message.payload?.value)
                }
            }
        }
    }
    
    private func handleDisconnection(error: Error?) {
        self.connectionState = ConnectionState()
        webSocketTask = nil
        heartbeatTask?.cancel()
        
        // Auto-reconnect if enabled
        if config.autoReconnect && retryCount < config.maxRetries {
            self.connectionState = ConnectionState(reconnecting: true)
            
            reconnectTask = Task {
                let delay = config.retryDelay * pow(2.0, Double(retryCount))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                retryCount += 1
                
                do {
                    try await performConnection()
                } catch {
                    // Retry failed, will try again unless max retries reached
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled && connectionState.connected {
                let ping = RealtimeMessage(type: "ping", channel: "", event: "")
                try? await sendMessage(ping)
                
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }
    
    private func sendMessage(_ message: RealtimeMessage) async throws {
        guard let webSocketTask = webSocketTask else {
            throw SelfDBError(
                message: "Not connected to realtime service",
                code: "NOT_CONNECTED"
            )
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let text = String(data: data, encoding: .utf8) ?? ""
        
        try await webSocketTask.send(.string(text))
    }
    
    private func resubscribeAll() async {
        for (_, subscription) in subscriptions {
            let (channel, event, _) = subscription
            let message = RealtimeMessage(
                type: "subscribe",
                channel: channel,
                event: event ?? "*"
            )
            
            try? await sendMessage(message)
        }
    }
    
    private func unsubscribe(subscriptionId: String) {
        guard let subscription = subscriptions.removeValue(forKey: subscriptionId) else {
            return
        }
        
        let (channel, event, _) = subscription
        let message = RealtimeMessage(
            type: "unsubscribe",
            channel: channel,
            event: event ?? "*"
        )
        
        Task {
            try? await sendMessage(message)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension RealtimeClient: URLSessionWebSocketDelegate {
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        // Connection opened
    }
    
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        handleDisconnection(error: nil)
    }
}