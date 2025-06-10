import XCTest
@testable import SelfDB

final class StorageTests: XCTestCase {
    var client: SelfDB!
    let testConfig = SelfDBConfig(
        apiURL: URL(string: "http://localhost:8000/api/v1")!,
        storageURL: URL(string: "http://localhost:8001")!,
        apiKey: "5d42be5658e3526e2c049a216b9512095c9b2b4d44a40a522fc62e29b5697529"
    )
    
    override func setUp() {
        super.setUp()
        client = SelfDB(config: testConfig)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testBucketStructure() {
        let bucket = Bucket(
            id: "bucket123",
            name: "test-bucket",
            description: "Test bucket",
            is_public: true,
            minio_bucket_name: "minio-test-bucket",
            owner_id: "user123",
            created_at: "2024-01-01T00:00:00Z",
            updated_at: "2024-01-01T00:00:00Z",
            file_count: 5,
            total_size: 1024
        )
        
        XCTAssertEqual(bucket.id, "bucket123")
        XCTAssertEqual(bucket.name, "test-bucket")
        XCTAssertEqual(bucket.description, "Test bucket")
        XCTAssertTrue(bucket.is_public)
        XCTAssertEqual(bucket.file_count, 5)
        XCTAssertEqual(bucket.total_size, 1024)
    }
    
    func testCreateBucketRequest() {
        let request = CreateBucketRequest(
            name: "test-bucket",
            description: "Test bucket for API testing",
            isPublic: true
        )
        
        XCTAssertEqual(request.name, "test-bucket")
        XCTAssertEqual(request.description, "Test bucket for API testing")
        XCTAssertTrue(request.is_public)
    }
    
    func testUpdateBucketRequest() {
        let request = UpdateBucketRequest(
            description: "Updated test bucket",
            isPublic: false
        )
        
        XCTAssertEqual(request.description, "Updated test bucket")
        XCTAssertEqual(request.is_public, false)
    }
    
    func testFileInfoStructure() {
        let fileInfo = FileInfo(
            id: "file123",
            filename: "test.txt",
            content_type: "text/plain",
            size: 1024,
            bucket_id: "bucket123",
            created_at: "2024-01-01T00:00:00Z",
            updated_at: "2024-01-01T00:00:00Z",
            is_public: true
        )
        
        XCTAssertEqual(fileInfo.id, "file123")
        XCTAssertEqual(fileInfo.filename, "test.txt")
        XCTAssertEqual(fileInfo.content_type, "text/plain")
        XCTAssertEqual(fileInfo.size, 1024)
        XCTAssertEqual(fileInfo.bucket_id, "bucket123")
        XCTAssertEqual(fileInfo.is_public, true)
    }
    
    func testInitiateUploadRequest() {
        let request = InitiateUploadRequest(
            filename: "test.txt",
            contentType: "text/plain",
            size: 1024,
            bucketId: "bucket123"
        )
        
        XCTAssertEqual(request.filename, "test.txt")
        XCTAssertEqual(request.content_type, "text/plain")
        XCTAssertEqual(request.size, 1024)
        XCTAssertEqual(request.bucket_id, "bucket123")
    }
    
    func testInitiateUploadResponse() {
        let fileMetadata = FileMetadata(
            filename: "test.txt",
            content_type: "text/plain",
            id: "file123",
            bucket_name: "test-bucket",
            object_name: "object123.txt",
            size: 1024,
            owner_id: "user123",
            bucket_id: "bucket123",
            created_at: "2024-01-01T00:00:00Z",
            updated_at: nil
        )
        
        let uploadInfo = PresignedUploadInfo(
            upload_url: "https://example.com/upload",
            upload_method: "PUT"
        )
        
        let response = InitiateUploadResponse(
            file_metadata: fileMetadata,
            presigned_upload_info: uploadInfo
        )
        
        XCTAssertEqual(response.file_metadata.id, "file123")
        XCTAssertEqual(response.presigned_upload_info.upload_url, "https://example.com/upload")
        XCTAssertEqual(response.presigned_upload_info.upload_method, "PUT")
    }
    
    func testFileDownloadInfo() {
        let fileMetadata = FileMetadata(
            filename: "test.txt",
            content_type: "text/plain",
            id: "file123",
            bucket_name: "test-bucket",
            object_name: "object123.txt",
            size: 1024,
            owner_id: "user123",
            bucket_id: "bucket123",
            created_at: "2024-01-01T00:00:00Z",
            updated_at: nil
        )
        
        let downloadInfo = FileDownloadInfo(
            file_metadata: fileMetadata,
            download_url: "https://example.com/download"
        )
        
        XCTAssertEqual(downloadInfo.download_url, "https://example.com/download")
        XCTAssertEqual(downloadInfo.file_metadata.id, "file123")
    }
    
    func testFileViewInfo() {
        let fileMetadata = FileMetadata(
            filename: "test.txt",
            content_type: "text/plain",
            id: "file123",
            bucket_name: "test-bucket",
            object_name: "object123.txt",
            size: 1024,
            owner_id: "user123",
            bucket_id: "bucket123",
            created_at: "2024-01-01T00:00:00Z",
            updated_at: nil
        )
        
        let viewInfo = FileViewInfo(
            file_metadata: fileMetadata,
            view_url: "https://example.com/view"
        )
        
        XCTAssertEqual(viewInfo.view_url, "https://example.com/view")
        XCTAssertEqual(viewInfo.file_metadata.id, "file123")
    }
}