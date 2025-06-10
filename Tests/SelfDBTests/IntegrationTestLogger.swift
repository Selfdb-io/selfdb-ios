import Foundation

/// Logger for integration tests with file output
public class IntegrationTestLogger {
    static let shared = IntegrationTestLogger()
    
    private init() {}
    
    func initializeTestLog() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "swift_test_results_\(timestamp).txt"
        
        IntegrationTestState.shared.testLogFilename = filename
        
        guard let fileURL = getLogFileURL(filename: filename) else {
            print("❌ Failed to create log file")
            return
        }
        
        FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        IntegrationTestState.shared.testLogFile = FileHandle(forWritingAtPath: fileURL.path)
        
        let header = """
        SelfDB Swift SDK Integration Test Results
        Test Date: \(DateFormatter.iso8601.string(from: Date()))
        Results File: \(filename)
        ================================================================================
        
        🚀 Starting SelfDB Swift SDK Integration Tests
        Backend URL: \(IntegrationTestConfig.backendURL)
        Storage URL: \(IntegrationTestConfig.storageURL)
        API Key: \(String(IntegrationTestConfig.apiKey.prefix(20)))...
        
        📝 Note: These tests run against a real SelfDB instance
        ================================================================================
        
        """
        
        writeToLog(header)
        print(header)
    }
    
    func logTestHeader(_ testName: String) {
        let header = """
        
        ============================================================
        Testing: \(testName)
        ============================================================
        """
        writeToLog(header)
        print(header)
    }
    
    func logTestResult(_ result: TestResult) {
        IntegrationTestState.shared.testResults.append(result)
        
        let status = result.success ? "✅ PASS" : "❌ FAIL"
        let statusCode = result.statusCode.map { " (Status: \($0))" } ?? ""
        let error = result.error.map { " - Error: \($0)" } ?? ""
        
        let logEntry = "\(status): \(result.description)\(statusCode)\(error)"
        writeToLog(logEntry)
        print(logEntry)
    }
    
    func logRequest(method: String, url: String, headers: [String: String]? = nil, body: Data? = nil) {
        let requestLog = "Request: \(method) \(url)"
        writeToLog(requestLog)
        print(requestLog)
        
        // Log curl example
        var curlCommand = "curl -X \(method) \"\(url)\""
        
        if let headers = headers {
            for (key, value) in headers {
                if key.lowercased() == "authorization" && value.hasPrefix("Bearer ") {
                    curlCommand += " \\\n  -H \"\(key): Bearer your_access_token\""
                } else if key.lowercased() == "apikey" {
                    curlCommand += " \\\n  -H \"\(key): your_api_key\""
                } else {
                    curlCommand += " \\\n  -H \"\(key): \(value)\""
                }
            }
        }
        
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            if let headers = headers, headers["Content-Type"] == "application/json" {
                curlCommand += " \\\n  -d '\(bodyString)'"
            } else {
                curlCommand += " \\\n  --data-binary '\(bodyString)'"
            }
        }
        
        let curlLog = "\nCurl example:\n\(curlCommand)\n"
        writeToLog(curlLog)
        
        writeToLog("-" * 50)
    }
    
    func logResponse(data: Data?, statusCode: Int, error: Error? = nil) {
        writeToLog("Status: \(statusCode)")
        print("Status: \(statusCode)")
        
        if let error = error {
            let errorLog = "Error: \(error.localizedDescription)"
            writeToLog(errorLog)
            print(errorLog)
        } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
            let responseLog = "Response: \(responseString)"
            writeToLog(responseLog)
            print("Response: \(responseString)")
            
            // Try to format as JSON for documentation
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonData, options: [.prettyPrinted]),
               let prettyJson = String(data: prettyData, encoding: .utf8) {
                let exampleResponse = "\nExample Response (\(statusCode)):\n```json\n\(prettyJson)\n```\n"
                writeToLog(exampleResponse)
            }
        }
        
        writeToLog("-" * 50)
    }
    
    func generateTestSummary() {
        let summary = """
        
        ================================================================================
        🏁 Swift SDK Integration Testing Complete!
        ================================================================================
        
        📊 TEST SUMMARY
        ================================================================================
        Total Tests: \(IntegrationTestState.shared.testResults.count)
        Passed: \(IntegrationTestState.shared.testResults.filter { $0.success }.count) ✅
        Failed: \(IntegrationTestState.shared.testResults.filter { !$0.success }.count) ❌
        Success Rate: \(String(format: "%.1f", Double(IntegrationTestState.shared.testResults.filter { $0.success }.count) / Double(IntegrationTestState.shared.testResults.count) * 100))%
        
        """
        
        writeToLog(summary)
        print(summary)
        
        let failedTests = IntegrationTestState.shared.testResults.filter { !$0.success }
        if !failedTests.isEmpty {
            let failureLog = "❌ FAILED TESTS:\n" + failedTests.map { "  - \($0.description): \($0.error ?? "Unknown error")" }.joined(separator: "\n")
            writeToLog(failureLog)
            print(failureLog)
        }
        
        let passedTests = IntegrationTestState.shared.testResults.filter { $0.success }
        if !passedTests.isEmpty {
            let successLog = "\n✅ PASSED TESTS:\n" + passedTests.map { "  - \($0.description)" }.joined(separator: "\n")
            writeToLog(successLog)
            print(successLog)
        }
        
        if let filename = IntegrationTestState.shared.testLogFilename {
            let logInfo = "\n📄 Test results saved to: \(filename)"
            writeToLog(logInfo)
            print(logInfo)
        }
    }
    
    func closeTestLog() {
        IntegrationTestState.shared.testLogFile?.closeFile()
        IntegrationTestState.shared.testLogFile = nil
    }
    
    private func writeToLog(_ content: String) {
        guard let fileHandle = IntegrationTestState.shared.testLogFile else { return }
        if let data = (content + "\n").data(using: .utf8) {
            fileHandle.write(data)
        }
    }
    
    private func getLogFileURL(filename: String) -> URL? {
        let currentDirectory = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: currentDirectory).appendingPathComponent(filename)
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

/// String extension for Python-like string multiplication
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}