#!/bin/bash
set -e

echo "🧪 Testing All Codemagic Workflows Locally"
echo "=========================================="
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a workflow test
run_workflow_test() {
    local workflow_name="$1"
    local test_script="$2"
    
    echo "🚀 Testing $workflow_name Workflow"
    echo "=================================="
    
    if [ ! -f "$test_script" ]; then
        echo "❌ Test script not found: $test_script"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$workflow_name - Script not found")
        return 1
    fi
    
    # Make script executable
    chmod +x "$test_script"
    
    # Run the test
    if bash "$test_script"; then
        echo "✅ $workflow_name workflow test PASSED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ $workflow_name workflow test FAILED"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$workflow_name")
    fi
    
    echo ""
    echo "=================================================="
    echo ""
}

# Test 1: Combined Workflow
run_workflow_test "Combined" "test_combined_workflow.sh"

# Test 2: Android Publish Workflow
run_workflow_test "Android Publish" "test_android_publish.sh"

# Test 3: iOS Publish Workflow (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    run_workflow_test "iOS Publish" "test_ios_publish.sh"
else
    echo "⚠️  Skipping iOS Publish workflow test (not on macOS)"
    echo ""
fi

# Final Summary
echo "🎯 FINAL TEST SUMMARY"
echo "===================="
echo ""
echo "📊 Test Results:"
echo "• Tests Passed: $TESTS_PASSED"
echo "• Tests Failed: $TESTS_FAILED"
echo "• Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 ALL WORKFLOW TESTS PASSED!"
    echo "✅ Your Codemagic workflows are ready for production!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Commit and push your changes to your repository"
    echo "2. Configure environment variables in Codemagic UI or via API"
    echo "3. Trigger builds on Codemagic"
    echo ""
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    echo ""
    echo "Failed Tests:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  • $test"
    done
    echo ""
    echo "🔧 Please fix the failing tests before deploying to Codemagic"
    exit 1
fi 