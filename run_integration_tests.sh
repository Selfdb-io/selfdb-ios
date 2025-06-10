#!/bin/bash

# SelfDB Swift SDK Integration Test Runner
# This script runs integration tests against a real SelfDB instance

echo "🚀 SelfDB Swift SDK Integration Test Runner"
echo "=============================================="

# Check if SelfDB is running
echo "📡 Checking SelfDB backend availability..."
if ! curl -f -s -H "anon-key: f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814" http://localhost:8000/api/v1/health > /dev/null; then
    echo "❌ SelfDB backend not available at http://localhost:8000"
    echo "Please start SelfDB before running integration tests"
    echo ""
    echo "To start SelfDB, run from the main SelfDB directory:"
    echo "  ./start.sh"
    exit 1
fi

echo "✅ SelfDB backend is running"

echo "📡 Checking SelfDB storage availability..."
if ! curl -f -s http://localhost:8001/health > /dev/null; then
    echo "❌ SelfDB storage not available at http://localhost:8001"
    echo "Please start SelfDB storage service before running integration tests"
    exit 1
fi

echo "✅ SelfDB storage service is running"

# Set environment variables for testing
export BACKEND_URL="http://localhost:8000/api/v1"
export STORAGE_URL="http://localhost:8001"
export API_KEY="f5b220a570cdce9f452dbe8103183edcffb6f25870412df696d727fcb2218814"

echo ""
echo "🧪 Running Swift SDK Integration Tests..."
echo "Backend URL: $BACKEND_URL"
echo "Storage URL: $STORAGE_URL"
echo "API Key: ${API_KEY:0:20}..."
echo ""

# Run the integration tests
swift test --filter IntegrationTestRunner

test_exit_code=$?

echo ""
echo "=============================================="

if [ $test_exit_code -eq 0 ]; then
    echo "✅ Integration tests completed successfully!"
else
    echo "❌ Integration tests failed with exit code: $test_exit_code"
fi

# Find and display the test results file
results_file=$(ls swift_test_results_*.txt 2>/dev/null | sort | tail -n 1)
if [ -n "$results_file" ]; then
    echo "📄 Test results saved to: $results_file"
    echo ""
    echo "📝 Test Summary:"
    echo "=================="
    tail -n 20 "$results_file"
else
    echo "⚠️  No test results file found"
fi

exit $test_exit_code