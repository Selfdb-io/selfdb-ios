import XCTest
@testable import SelfDB

final class IntegrationTestRunner: XCTestCase {
    let logger = IntegrationTestLogger.shared
    let state = IntegrationTestState.shared
    var authenticatedClient: SelfDB?
    
    override func setUp() {
        super.setUp()
        logger.initializeTestLog()
        state.reset()
    }
    
    override func tearDown() {
        logger.generateTestSummary()
        logger.closeTestLog()
        super.tearDown()
    }
    
    func testBasicStructureTests() {
        logger.logTestHeader("SelfDB Swift SDK Basic Structure Tests")
        
        // Test configuration
        let config = IntegrationTestConfig.testConfig
        XCTAssertNotNil(config)
        logger.logTestResult(TestResult(
            testName: "testBasicStructureTests",
            description: "Configuration Creation",
            success: true
        ))
        
        // Test client initialization
        let client = SelfDB(config: config)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.auth)
        XCTAssertNotNil(client.database)
        XCTAssertNotNil(client.storage)
        logger.logTestResult(TestResult(
            testName: "testBasicStructureTests",
            description: "Client Initialization",
            success: true
        ))
        
        // Test data structures
        let registerRequest = RegisterRequest(email: "test@example.com", password: "password123")
        XCTAssertEqual(registerRequest.email, "test@example.com")
        logger.logTestResult(TestResult(
            testName: "testBasicStructureTests",
            description: "Registration Request Structure",
            success: true
        ))
        
        let loginRequest = LoginRequest(username: "test@example.com", password: "password123")
        XCTAssertEqual(loginRequest.username, "test@example.com")
        logger.logTestResult(TestResult(
            testName: "testBasicStructureTests",
            description: "Login Request Structure",
            success: true
        ))
        
        print("✅ All basic structure tests passed")
    }
    
    func testRealAuthentication() async {
        logger.logTestHeader("Real Authentication Against SelfDB Instance")
        
        let client = SelfDB(config: IntegrationTestConfig.testConfig)
        self.authenticatedClient = client
        let timestamp = Int(Date().timeIntervalSince1970)
        let testEmail = "\(IntegrationTestConfig.testEmailBase)_\(timestamp)@example.com"
        
        // Test registration
        let registerResult = await client.auth.register(
            email: testEmail,
            password: IntegrationTestConfig.testPassword
        )
        
        if registerResult.isSuccess, let user = registerResult.data {
            state.userId = user.id
            state.testEmail = testEmail
            logger.logTestResult(TestResult(
                testName: "testRealAuthentication",
                description: "User Registration",
                success: true,
                statusCode: registerResult.statusCode
            ))
            print("✅ Registration successful for: \(testEmail)")
            
            // Test login
            let loginResult = await client.auth.login(
                email: testEmail,
                password: IntegrationTestConfig.testPassword
            )
            
            if loginResult.isSuccess, let loginResponse = loginResult.data {
                state.accessToken = loginResponse.access_token
                logger.logTestResult(TestResult(
                    testName: "testRealAuthentication",
                    description: "User Login",
                    success: true,
                    statusCode: loginResult.statusCode
                ))
                print("✅ Login successful")
                
                // Test refresh token
                if let _ = loginResponse.refresh_token {
                    let refreshResult = await client.auth.refreshToken()
                    if refreshResult.isSuccess {
                        logger.logTestResult(TestResult(
                            testName: "testRealAuthentication",
                            description: "Refresh Token",
                            success: true,
                            statusCode: refreshResult.statusCode
                        ))
                        print("✅ Token refresh successful")
                    } else {
                        logger.logTestResult(TestResult(
                            testName: "testRealAuthentication",
                            description: "Refresh Token",
                            success: false,
                            statusCode: refreshResult.statusCode,
                            error: refreshResult.error?.localizedDescription
                        ))
                        print("❌ Token refresh failed: \(refreshResult.error?.localizedDescription ?? "Unknown error")")
                    }
                }
                
            } else {
                logger.logTestResult(TestResult(
                    testName: "testRealAuthentication",
                    description: "User Login",
                    success: false,
                    statusCode: loginResult.statusCode,
                    error: loginResult.error?.localizedDescription
                ))
                print("❌ Login failed: \(loginResult.error?.localizedDescription ?? "Unknown error")")
            }
            
        } else {
            logger.logTestResult(TestResult(
                testName: "testRealAuthentication",
                description: "User Registration",
                success: false,
                statusCode: registerResult.statusCode,
                error: registerResult.error?.localizedDescription
            ))
            print("❌ Registration failed: \(registerResult.error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func testComprehensiveUserOperations() async {
        logger.logTestHeader("Comprehensive User Management")
        
        guard let client = authenticatedClient else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveUserOperations",
                description: "Authentication Required",
                success: false,
                error: "No authenticated client available"
            ))
            print("❌ No authenticated client available for user operations")
            return
        }
        
        // Test get current user
        let currentUserResult = await client.auth.getCurrentUser()
        if currentUserResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveUserOperations",
                description: "Get Current User",
                success: true,
                statusCode: currentUserResult.statusCode
            ))
            print("✅ Retrieved current user successfully")
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveUserOperations",
                description: "Get Current User",
                success: false,
                statusCode: currentUserResult.statusCode,
                error: currentUserResult.error?.localizedDescription
            ))
            print("❌ Failed to get current user: \(currentUserResult.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Note: User update and password change methods may not be implemented yet in this SDK version
        // These would require additional API endpoints to be added
    }
    
    func testComprehensiveDatabaseOperations() async {
        logger.logTestHeader("Comprehensive Database Operations")
        
        guard let client = authenticatedClient else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Authentication Required",
                success: false,
                error: "No authenticated client available"
            ))
            print("❌ No authenticated client available for database operations")
            return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let testTableName = "test_products_\(timestamp)"
        
        // Test list tables
        let tablesResult = await client.database.listTables()
        if tablesResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "List Tables",
                success: true,
                statusCode: tablesResult.statusCode
            ))
            print("✅ Listed tables successfully")
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "List Tables",
                success: false,
                statusCode: tablesResult.statusCode,
                error: tablesResult.error?.localizedDescription
            ))
            print("❌ Failed to list tables: \(tablesResult.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Test get table details (users table should exist)
        let tableDetailsResult = await client.database.getTable("users")
        if tableDetailsResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Get Table Details",
                success: true,
                statusCode: tableDetailsResult.statusCode
            ))
            print("✅ Retrieved table details successfully")
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Get Table Details",
                success: false,
                statusCode: tableDetailsResult.statusCode,
                error: tableDetailsResult.error?.localizedDescription
            ))
            print("❌ Failed to get table details: \(tableDetailsResult.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Test get table data
        let tableDataResult = await client.database.getTableData("users", page: 1, pageSize: 5)
        if tableDataResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Get Table Data",
                success: true,
                statusCode: tableDataResult.statusCode
            ))
            print("✅ Retrieved table data successfully")
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Get Table Data",
                success: false,
                statusCode: tableDataResult.statusCode,
                error: tableDataResult.error?.localizedDescription
            ))
            print("❌ Failed to get table data: \(tableDataResult.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Test create table
        let columns = [
            CreateColumnRequest(name: "id", type: "UUID", nullable: false, primaryKey: true, defaultValue: "gen_random_uuid()"),
            CreateColumnRequest(name: "name", type: "VARCHAR(255)", nullable: false),
            CreateColumnRequest(name: "price", type: "DECIMAL(10,2)", nullable: true)
        ]
        
        let createTableRequest = CreateTableRequest(name: testTableName, columns: columns, description: "Test products table")
        let createTableResult = await client.database.createTable(createTableRequest)
        
        if createTableResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Create Test Table",
                success: true,
                statusCode: createTableResult.statusCode
            ))
            print("✅ Created test table successfully")
            
            // Test insert data
            let insertData = ["name": "Test Product", "price": "19.99"]
            let insertResult = await client.database.insertRow(testTableName, data: insertData)
            
            if insertResult.isSuccess, let insertedData = insertResult.data {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Insert Test Data",
                    success: true,
                    statusCode: insertResult.statusCode
                ))
                print("✅ Inserted test data successfully")
                
                // Test update data
                if let idAnyCodable = insertedData["id"], let recordId = idAnyCodable.value as? String {
                    let updateData = ["price": "29.99"]
                    let updateResult = await client.database.updateRow(testTableName, rowId: recordId, data: updateData)
                    
                    if updateResult.isSuccess {
                        logger.logTestResult(TestResult(
                            testName: "testComprehensiveDatabaseOperations",
                            description: "Update Test Data",
                            success: true,
                            statusCode: updateResult.statusCode
                        ))
                        print("✅ Updated test data successfully")
                    } else {
                        logger.logTestResult(TestResult(
                            testName: "testComprehensiveDatabaseOperations",
                            description: "Update Test Data",
                            success: false,
                            statusCode: updateResult.statusCode,
                            error: updateResult.error?.localizedDescription
                        ))
                        print("❌ Failed to update test data: \(updateResult.error?.localizedDescription ?? "Unknown error")")
                    }
                }
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Insert Test Data",
                    success: false,
                    statusCode: insertResult.statusCode,
                    error: insertResult.error?.localizedDescription
                ))
                print("❌ Failed to insert test data: \(insertResult.error?.localizedDescription ?? "Unknown error")")
            }
            
            // Test update table description
            let updateTableRequest = UpdateTableRequest(description: "Updated test products table")
            let updateTableResult = await client.database.updateTable(testTableName, updateTableRequest)
            if updateTableResult.isSuccess {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Update Table Description",
                    success: true,
                    statusCode: updateTableResult.statusCode
                ))
                print("✅ Updated table description successfully")
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Update Table Description",
                    success: false,
                    statusCode: updateTableResult.statusCode,
                    error: updateTableResult.error?.localizedDescription
                ))
                print("❌ Failed to update table description: \(updateTableResult.error?.localizedDescription ?? "Unknown error")")
            }
            
            // Test delete table
            let deleteTableResult = await client.database.deleteTable(testTableName)
            if deleteTableResult.isSuccess {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Delete Test Table",
                    success: true,
                    statusCode: deleteTableResult.statusCode
                ))
                print("✅ Deleted test table successfully")
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveDatabaseOperations",
                    description: "Delete Test Table",
                    success: false,
                    statusCode: deleteTableResult.statusCode,
                    error: deleteTableResult.error?.localizedDescription
                ))
                print("❌ Failed to delete test table: \(deleteTableResult.error?.localizedDescription ?? "Unknown error")")
            }
            
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveDatabaseOperations",
                description: "Create Test Table",
                success: false,
                statusCode: createTableResult.statusCode,
                error: createTableResult.error?.localizedDescription
            ))
            print("❌ Failed to create test table: \(createTableResult.error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func testComprehensiveStorageOperations() async {
        logger.logTestHeader("Comprehensive Storage Operations")
        
        guard let client = authenticatedClient else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveStorageOperations",
                description: "Authentication Required",
                success: false,
                error: "No authenticated client available"
            ))
            print("❌ No authenticated client available for storage operations")
            return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let testBucketName = "test-bucket-\(timestamp)"
        
        // Test list buckets
        let bucketsResult = await client.storage.listBuckets()
        if bucketsResult.isSuccess {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveStorageOperations",
                description: "List Storage Buckets",
                success: true,
                statusCode: bucketsResult.statusCode
            ))
            if let buckets = bucketsResult.data {
                print("✅ Found \(buckets.count) buckets")
            }
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveStorageOperations",
                description: "List Storage Buckets",
                success: false,
                statusCode: bucketsResult.statusCode,
                error: bucketsResult.error?.localizedDescription
            ))
            print("❌ Failed to list buckets: \(bucketsResult.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Test create bucket
        let createBucketRequest = CreateBucketRequest(name: testBucketName, description: "Test bucket for API testing", isPublic: true)
        let createBucketResult = await client.storage.createBucket(createBucketRequest)
        
        if createBucketResult.isSuccess, let bucket = createBucketResult.data {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveStorageOperations",
                description: "Create Bucket",
                success: true,
                statusCode: createBucketResult.statusCode
            ))
            print("✅ Created bucket successfully")
            
            // Test get bucket details
            let bucketDetailsResult = await client.storage.getBucket(bucket.id)
            if bucketDetailsResult.isSuccess {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Get Bucket Details",
                    success: true,
                    statusCode: bucketDetailsResult.statusCode
                ))
                print("✅ Retrieved bucket details successfully")
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Get Bucket Details",
                    success: false,
                    statusCode: bucketDetailsResult.statusCode,
                    error: bucketDetailsResult.error?.localizedDescription
                ))
                print("❌ Failed to get bucket details: \(bucketDetailsResult.error?.localizedDescription ?? "Unknown error")")
            }
            
            // Test list bucket files
            let bucketFilesResult = await client.storage.listBucketFiles(bucket.id)
            if bucketFilesResult.isSuccess {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "List Bucket Files",
                    success: true,
                    statusCode: bucketFilesResult.statusCode
                ))
                print("✅ Listed bucket files successfully")
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "List Bucket Files",
                    success: false,
                    statusCode: bucketFilesResult.statusCode,
                    error: bucketFilesResult.error?.localizedDescription
                ))
                print("❌ Failed to list bucket files: \(bucketFilesResult.error?.localizedDescription ?? "Unknown error")")
            }
            
            // Test file operations
            let testContent = "This is a test document."
            let testData = testContent.data(using: .utf8)!
            
            // Test initiate upload
            let uploadRequest = InitiateUploadRequest(
                filename: "test-document.txt",
                contentType: "text/plain",
                size: testData.count,
                bucketId: bucket.id
            )
            
            let uploadResult = await client.storage.initiateUpload(uploadRequest)
            if uploadResult.isSuccess, let uploadResponse = uploadResult.data {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Initiate File Upload",
                    success: true,
                    statusCode: uploadResult.statusCode
                ))
                print("✅ Initiated file upload successfully")
                
                // Test actual upload to storage service
                let actualUploadResult = await client.storage.uploadData(
                    testData,
                    to: uploadResponse.presigned_upload_info.upload_url,
                    contentType: "text/plain"
                )
                
                if actualUploadResult.isSuccess {
                    logger.logTestResult(TestResult(
                        testName: "testComprehensiveStorageOperations",
                        description: "Upload File to Storage",
                        success: true,
                        statusCode: actualUploadResult.statusCode
                    ))
                    print("✅ Uploaded file to storage successfully")
                    
                    // Test get download info
                    let downloadInfoResult = await client.storage.getFileDownloadInfo(uploadResponse.file_metadata.id)
                    if downloadInfoResult.isSuccess {
                        logger.logTestResult(TestResult(
                            testName: "testComprehensiveStorageOperations",
                            description: "Get File Download Info",
                            success: true,
                            statusCode: downloadInfoResult.statusCode
                        ))
                        print("✅ Retrieved file download info successfully")
                        
                        // Note: Actual file download would require implementing a download method
                        // For now, we just test getting the download info
                        
                    } else {
                        logger.logTestResult(TestResult(
                            testName: "testComprehensiveStorageOperations",
                            description: "Get File Download Info",
                            success: false,
                            statusCode: downloadInfoResult.statusCode,
                            error: downloadInfoResult.error?.localizedDescription
                        ))
                        print("❌ Failed to get file download info: \(downloadInfoResult.error?.localizedDescription ?? "Unknown error")")
                    }
                } else {
                    logger.logTestResult(TestResult(
                        testName: "testComprehensiveStorageOperations",
                        description: "Upload File to Storage",
                        success: false,
                        statusCode: actualUploadResult.statusCode,
                        error: actualUploadResult.error?.localizedDescription
                    ))
                    print("❌ Failed to upload file to storage: \(actualUploadResult.error?.localizedDescription ?? "Unknown error")")
                }
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Initiate File Upload",
                    success: false,
                    statusCode: uploadResult.statusCode,
                    error: uploadResult.error?.localizedDescription
                ))
                print("❌ Failed to initiate file upload: \(uploadResult.error?.localizedDescription ?? "Unknown error")")
            }
            
            // Test update bucket
            let updateBucketRequest = UpdateBucketRequest(description: "Updated test bucket")
            let updateBucketResult = await client.storage.updateBucket(bucket.id, updateBucketRequest)
            
            if updateBucketResult.isSuccess {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Update Bucket",
                    success: true,
                    statusCode: updateBucketResult.statusCode
                ))
                print("✅ Updated bucket successfully")
            } else {
                logger.logTestResult(TestResult(
                    testName: "testComprehensiveStorageOperations",
                    description: "Update Bucket",
                    success: false,
                    statusCode: updateBucketResult.statusCode,
                    error: updateBucketResult.error?.localizedDescription
                ))
                print("❌ Failed to update bucket: \(updateBucketResult.error?.localizedDescription ?? "Unknown error")")
            }
            
        } else {
            logger.logTestResult(TestResult(
                testName: "testComprehensiveStorageOperations",
                description: "Create Bucket",
                success: false,
                statusCode: createBucketResult.statusCode,
                error: createBucketResult.error?.localizedDescription
            ))
            print("❌ Failed to create bucket: \(createBucketResult.error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func testFullIntegrationSuite() async {
        // Run all tests in sequence
        testBasicStructureTests()
        await testRealAuthentication()
        await testComprehensiveUserOperations()
        await testComprehensiveDatabaseOperations()
        await testComprehensiveStorageOperations()
        
        // Final summary
        let totalTests = state.testResults.count
        let passedTests = state.testResults.filter { $0.success }.count
        let failedTests = totalTests - passedTests
        
        if failedTests == 0 {
            print("\n🎉 All integration tests passed! (\(totalTests)/\(totalTests))")
        } else {
            print("\n⚠️ Integration tests completed with \(failedTests) failures (\(passedTests)/\(totalTests) passed)")
        }
        
        logger.logTestResult(TestResult(
            testName: "testFullIntegrationSuite",
            description: "Full Integration Suite",
            success: failedTests == 0
        ))
    }
}