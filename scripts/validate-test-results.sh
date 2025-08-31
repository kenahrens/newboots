#!/usr/bin/env bash
# validate-test-results.sh
# Validation script for reverse proxy recording test results

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROXYMOCK_DIR="$PROJECT_ROOT/proxymock"

# Check if proxymock directory exists
if [ ! -d "$PROXYMOCK_DIR" ]; then
    log_error "Proxymock directory not found: $PROXYMOCK_DIR"
    exit 1
fi

echo "=== Reverse Proxy Recording Test Results Validation ==="
echo "Project Root: $PROJECT_ROOT"
echo "Proxymock Directory: $PROXYMOCK_DIR"
echo

# Find all recording directories
log_info "Scanning for recording directories..."
RECORDING_DIRS=($(find "$PROXYMOCK_DIR" -name "recorded-*" -type d | sort))
MOCK_DIRS=($(find "$PROXYMOCK_DIR" -name "mocked-*" -type d | sort))

echo "Found ${#RECORDING_DIRS[@]} recording directories"
echo "Found ${#MOCK_DIRS[@]} mock directories"
echo

# Analyze each recording directory
for dir in "${RECORDING_DIRS[@]}"; do
    echo "=== Analyzing Recording Directory: $(basename "$dir") ==="
    
    if [ ! -d "$dir/localhost" ]; then
        log_warning "No localhost subdirectory found"
        continue
    fi
    
    # Count files
    total_files=$(find "$dir/localhost" -name "*.md" | wc -l)
    echo "Total MD files: $total_files"
    
    if [ "$total_files" -eq 0 ]; then
        log_warning "No MD files found"
        continue
    fi
    
    # Analyze traffic patterns
    inbound_files=$(grep -l "direction: IN" "$dir/localhost"/*.md 2>/dev/null | wc -l)
    outbound_files=$(grep -l "direction: OUT" "$dir/localhost"/*.md 2>/dev/null | wc -l)
    reactor_files=$(grep -l "ReactorNetty" "$dir/localhost"/*.md 2>/dev/null | wc -l)
    numbers_files=$(grep -l "numbersapi.com" "$dir/localhost"/*.md 2>/dev/null | wc -l)
    hf_files=$(grep -l "huggingface.co" "$dir/localhost"/*.md 2>/dev/null | wc -l)
    
    echo "  Inbound traffic: $inbound_files files"
    echo "  Outbound traffic: $outbound_files files"
    echo "  ReactorNetty traffic: $reactor_files files"
    echo "  Numbers API traffic: $numbers_files files"
    echo "  Hugging Face API traffic: $hf_files files"
    
    # Check file structure
    valid_files=0
    for file in "$dir/localhost"/*.md; do
        if [ -f "$file" ]; then
            if grep -q "### REQUEST ###" "$file" && \
               grep -q "### RESPONSE" "$file" && \
               grep -q "### METADATA ###" "$file"; then
                valid_files=$((valid_files + 1))
            fi
        fi
    done
    
    echo "  Valid file structure: $valid_files/$total_files files"
    
    # Show sample file content
    if [ "$total_files" -gt 0 ]; then
        echo "  Sample file content:"
        sample_file=$(find "$dir/localhost" -name "*.md" | head -1)
        if [ -n "$sample_file" ]; then
            echo "    File: $(basename "$sample_file")"
            echo "    Size: $(wc -c < "$sample_file") bytes"
            echo "    Lines: $(wc -l < "$sample_file")"
            
            # Show metadata section
            echo "    Metadata:"
            sed -n '/### METADATA ###/,/^$/p' "$sample_file" | head -5 | sed 's/^/      /'
        fi
    fi
    
    echo
done

# Analyze each mock directory
for dir in "${MOCK_DIRS[@]}"; do
    echo "=== Analyzing Mock Directory: $(basename "$dir") ==="
    
    # Count files
    total_files=$(find "$dir" -name "*.md" | wc -l)
    echo "Total MD files: $total_files"
    
    if [ "$total_files" -eq 0 ]; then
        log_warning "No MD files found"
        continue
    fi
    
    # Analyze mock patterns
    match_files=$(grep -l "MATCH" "$dir"/*.md 2>/dev/null | wc -l)
    no_match_files=$(grep -l "NO_MATCH" "$dir"/*.md 2>/dev/null | wc -l)
    passthrough_files=$(grep -l "PASSTHROUGH" "$dir"/*.md 2>/dev/null | wc -l)
    numbers_files=$(grep -l "numbersapi.com" "$dir"/*.md 2>/dev/null | wc -l)
    hf_files=$(grep -l "huggingface.co" "$dir"/*.md 2>/dev/null | wc -l)
    
    echo "  MATCH status: $match_files files"
    echo "  NO_MATCH status: $no_match_files files"
    echo "  PASSTHROUGH status: $passthrough_files files"
    echo "  Numbers API references: $numbers_files files"
    echo "  Hugging Face API references: $hf_files files"
    
    # Show sample file content
    if [ "$total_files" -gt 0 ]; then
        echo "  Sample file content:"
        sample_file=$(find "$dir" -name "*.md" | head -1)
        if [ -n "$sample_file" ]; then
            echo "    File: $(basename "$sample_file")"
            echo "    Size: $(wc -c < "$sample_file") bytes"
            echo "    Lines: $(wc -l < "$sample_file")"
            
            # Show status information
            echo "    Status:"
            grep -E "(MATCH|NO_MATCH|PASSTHROUGH)" "$sample_file" | head -3 | sed 's/^/      /'
        fi
    fi
    
    echo
done

# Summary report
echo "=== Summary Report ==="

# Check for test log file
if [ -f "test-reverse-proxy-recording.log" ]; then
    echo "Test log file: test-reverse-proxy-recording.log"
    echo "Log file size: $(wc -c < test-reverse-proxy-recording.log) bytes"
    echo "Log file lines: $(wc -l < test-reverse-proxy-recording.log)"
    
    # Extract test results
    passed=$(grep -c "PASSED" test-reverse-proxy-recording.log || echo "0")
    failed=$(grep -c "FAILED" test-reverse-proxy-recording.log || echo "0")
    
    echo "Tests passed: $passed"
    echo "Tests failed: $failed"
    
    if [ "$failed" -eq 0 ]; then
        log_success "All tests appear to have passed!"
    else
        log_error "Some tests failed. Check the log file for details."
    fi
else
    log_warning "Test log file not found"
fi

echo
echo "=== Validation Complete ==="
