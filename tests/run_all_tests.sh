#!/bin/bash
# =============================================================================
# Master Test Runner
# =============================================================================
# Runs all test scripts in the tests directory and provides a summary report
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Model Experiments Test Suite Runner            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find all test scripts
TEST_SCRIPTS=($(find "$SCRIPT_DIR" -name "test_*.sh" -type f | sort))

if [ ${#TEST_SCRIPTS[@]} -eq 0 ]; then
    echo -e "${RED}No test scripts found in $SCRIPT_DIR${NC}"
    exit 1
fi

echo -e "${CYAN}Found ${#TEST_SCRIPTS[@]} test suite(s)${NC}"
echo ""

# Run each test script
for TEST_SCRIPT in "${TEST_SCRIPTS[@]}"; do
    TEST_NAME=$(basename "$TEST_SCRIPT" .sh)
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${BOLD}Running: $TEST_NAME${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    # Run the test and capture output
    if OUTPUT=$("$TEST_SCRIPT" 2>&1); then
        PASSED_SUITES=$((PASSED_SUITES + 1))
        
        # Extract test statistics from output
        if echo "$OUTPUT" | grep -q "Total Tests Run:"; then
            SUITE_TESTS=$(echo "$OUTPUT" | grep "Total Tests Run:" | awk '{print $4}')
            SUITE_PASSED=$(echo "$OUTPUT" | grep "Tests Passed:" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $3}')
            SUITE_FAILED=$(echo "$OUTPUT" | grep "Tests Failed:" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $3}')
            
            TOTAL_TESTS=$((TOTAL_TESTS + SUITE_TESTS))
            TOTAL_PASSED=$((TOTAL_PASSED + SUITE_PASSED))
            TOTAL_FAILED=$((TOTAL_FAILED + SUITE_FAILED))
            
            echo -e "${GREEN}✓ Suite PASSED${NC} - $SUITE_PASSED/$SUITE_TESTS tests passed"
        else
            echo -e "${GREEN}✓ Suite PASSED${NC}"
        fi
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        
        # Extract test statistics even if failed
        if echo "$OUTPUT" | grep -q "Total Tests Run:"; then
            SUITE_TESTS=$(echo "$OUTPUT" | grep "Total Tests Run:" | awk '{print $4}')
            SUITE_PASSED=$(echo "$OUTPUT" | grep "Tests Passed:" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $3}')
            SUITE_FAILED=$(echo "$OUTPUT" | grep "Tests Failed:" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $3}')
            
            TOTAL_TESTS=$((TOTAL_TESTS + SUITE_TESTS))
            TOTAL_PASSED=$((TOTAL_PASSED + SUITE_PASSED))
            TOTAL_FAILED=$((TOTAL_FAILED + SUITE_FAILED))
            
            echo -e "${RED}✗ Suite FAILED${NC} - $SUITE_PASSED/$SUITE_TESTS tests passed"
        else
            echo -e "${RED}✗ Suite FAILED${NC}"
        fi
        
        # Show last 20 lines of output for debugging
        echo ""
        echo -e "${YELLOW}Last 20 lines of output:${NC}"
        echo "$OUTPUT" | tail -20
    fi
done

# Print final summary
echo ""
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Final Test Summary                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Test Suites:"
echo "  Total:           $TOTAL_SUITES"
echo -e "  ${GREEN}Passed:          $PASSED_SUITES${NC}"
echo -e "  ${RED}Failed:          $FAILED_SUITES${NC}"
echo ""
echo "Individual Tests:"
echo "  Total:           $TOTAL_TESTS"
echo -e "  ${GREEN}Passed:          $TOTAL_PASSED${NC}"
echo -e "  ${RED}Failed:          $TOTAL_FAILED${NC}"
echo ""

# Calculate and display pass rates
if [ $TOTAL_SUITES -gt 0 ]; then
    SUITE_PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_SUITES/$TOTAL_SUITES)*100}")
    echo "Suite Pass Rate:     $SUITE_PASS_RATE%"
fi

if [ $TOTAL_TESTS -gt 0 ]; then
    TEST_PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_PASSED/$TOTAL_TESTS)*100}")
    echo "Test Pass Rate:      $TEST_PASS_RATE%"
fi

echo ""

# Final result
if [ $FAILED_SUITES -eq 0 ] && [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ SOME TESTS FAILED${NC}"
    exit 1
fi

