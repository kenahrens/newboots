#!/usr/bin/env bash
# comprehensive-reverse-proxy-test.sh
# Complete test of reverse proxy recording per examples/REVERSE-PROXY-RECORDING.md

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

APP_PORT=8080
PROXY_PORT=4143
NUMBERS_MAP_PORT=65080
HF_MAP_PORT=65081
RECORDING_DIR="proxymock/recorded-$(date +%Y-%m-%d_%H-%M-%S)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

cleanup() {
    log_info "Cleaning up processes..."
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 2
}

wait_for_port() {
    local port=$1
    local max_attempts=30
    for i in $(seq 1 $max_attempts); do
        if lsof -i :$port >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

wait_for_app() {
    local max_attempts=30
    for i in $(seq 1 $max_attempts); do
        if curl -s http://localhost:$APP_PORT/healthz >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
    done
    return 1
}

# Test 1: Baseline (no proxymock)
test_baseline() {
    log_info "=== TEST 1: BASELINE (NO PROXYMOCK) ==="
    
    MYSQL_PORT=3307 MONGODB_PORT=27017 mvn spring-boot:run > baseline.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Baseline app failed to start"
        return 1
    fi
    
    log_info "Capturing baseline responses..."
    echo "=== BASELINE RESPONSES ===" > baseline-responses.txt
    echo "Numbers API:" >> baseline-responses.txt
    curl -s "http://localhost:$APP_PORT/numberfact" >> baseline-responses.txt
    echo -e "\nHugging Face API:" >> baseline-responses.txt  
    curl -s "http://localhost:$APP_PORT/models/openai" >> baseline-responses.txt
    
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    sleep 2
    
    log_success "Baseline test completed"
    return 0
}

# Test 2: Proxymock recording
test_proxymock_recording() {
    log_info "=== TEST 2: PROXYMOCK RECORDING ==="
    
    # Start proxymock with all mappings
    proxymock record \
        --map $NUMBERS_MAP_PORT=http://numbersapi.com:80 \
        --map $HF_MAP_PORT=https://huggingface.co:443 \
        --app-port $APP_PORT \
        --out "$RECORDING_DIR" > proxymock.log 2>&1 &
    
    # Wait for proxymock to start
    if ! wait_for_port $PROXY_PORT || ! wait_for_port $NUMBERS_MAP_PORT || ! wait_for_port $HF_MAP_PORT; then
        log_error "Proxymock failed to start on required ports"
        return 1
    fi
    
    # Start app with environment overrides - use HTTPS for Hugging Face API
    NUMBERS_API_BASE="http://localhost:$NUMBERS_MAP_PORT" \
    HF_API_BASE="https://localhost:$HF_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run > proxymock-app.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Proxymock app failed to start"
        return 1
    fi
    
    log_info "Making test calls for all traffic types..."
    
    # 1. Inbound traffic via proxy
    curl -s "http://localhost:$PROXY_PORT/" >/dev/null
    curl -s "http://localhost:$PROXY_PORT/healthz" >/dev/null
    
    # 2. External API calls via app
    curl -s "http://localhost:$APP_PORT/numberfact" > proxymock-numberfact.txt
    curl -s "http://localhost:$APP_PORT/models/openai" > proxymock-models.txt
    
    # Stop processes
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 3
    
    log_success "Proxymock recording completed"
    return 0
}

# Test 3: Validate recording structure
test_validate_structure() {
    log_info "=== TEST 3: VALIDATE RECORDING STRUCTURE ==="
    
    # Check for 3 required subdirectories
    if [ ! -d "$RECORDING_DIR/localhost" ]; then
        log_error "Missing localhost directory for inbound traffic"
        return 1
    fi
    
    if [ ! -d "$RECORDING_DIR/numbersapi.com" ]; then
        log_error "Missing numbersapi.com directory for Numbers API traffic"
        return 1
    fi
    
    if [ ! -d "$RECORDING_DIR/huggingface.co" ]; then
        log_error "Missing huggingface.co directory for Hugging Face API traffic"
        return 1
    fi
    
    # Count files
    local localhost_files=$(find "$RECORDING_DIR/localhost" -name "*.md" | wc -l)
    local numbers_files=$(find "$RECORDING_DIR/numbersapi.com" -name "*.md" | wc -l)
    local hf_files=$(find "$RECORDING_DIR/huggingface.co" -name "*.md" | wc -l)
    
    log_info "Files captured:"
    log_info "  localhost (inbound): $localhost_files files"
    log_info "  numbersapi.com (outbound): $numbers_files files"
    log_info "  huggingface.co (outbound): $hf_files files"
    
    # Validate file structure
    valid_files=0
    total_files=0
    for dir in localhost numbersapi.com huggingface.co; do
        for file in "$RECORDING_DIR/$dir"/*.md; do
            if [ -f "$file" ]; then
                total_files=$((total_files + 1))
                if (grep -q "### REQUEST" "$file" || grep -q "### REQUEST (TEST)" "$file") && \
                   grep -q "### RESPONSE" "$file" && \
                   grep -q "### METADATA ###" "$file"; then
                    valid_files=$((valid_files + 1))
                else
                    log_error "Invalid file structure in $file"
                    return 1
                fi
            fi
        done
    done
    
    log_info "Valid file structure: $valid_files/$total_files files"
    
    log_success "All 3 directories created with valid RRPair files"
    return 0
}

# Test 4: Mock server test
test_mock_server() {
    log_info "=== TEST 4: MOCK SERVER TEST ==="
    
    local mock_dir="proxymock/mocked-$(date +%Y-%m-%d_%H-%M-%S)"
    
    # Start mock server
    proxymock mock \
        --map $NUMBERS_MAP_PORT=http://numbersapi.com:80 \
        --map $HF_MAP_PORT=https://huggingface.co:443 \
        --in "$RECORDING_DIR" \
        --out "$mock_dir" > mock.log 2>&1 &
    
    if ! wait_for_port $NUMBERS_MAP_PORT || ! wait_for_port $HF_MAP_PORT; then
        log_error "Mock server failed to start"
        return 1
    fi
    
    # Test mock server with HTTPS for Hugging Face API
    NUMBERS_API_BASE="http://localhost:$NUMBERS_MAP_PORT" \
    HF_API_BASE="https://localhost:$HF_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run > mock-app.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Mock app failed to start"
        return 1
    fi
    
    # Test responses
    curl -s "http://localhost:$APP_PORT/numberfact" > mock-numberfact.txt
    curl -s "http://localhost:$APP_PORT/models/openai" > mock-models.txt
    
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 2
    
    log_success "Mock server test completed"
    return 0
}

# Test 5: Redirect bypass validation
test_redirect_bypass_validation() {
    log_info "=== TEST 5: REDIRECT BYPASS VALIDATION ==="
    
    # This test validates that when Hugging Face API returns a 301 redirect,
    # the WebClient follows the redirect directly to https://huggingface.co,
    # bypassing proxymock entirely
    
    log_info "Starting proxymock with HTTP mapping for Hugging Face..."
    proxymock record \
        --map $HF_MAP_PORT=http://huggingface.co:80 \
        --app-port $APP_PORT \
        --out "proxymock/redirect-test-$(date +%Y-%m-%d_%H-%M-%S)" > redirect-proxymock.log 2>&1 &
    
    if ! wait_for_port $HF_MAP_PORT; then
        log_error "Proxymock failed to start for redirect test"
        return 1
    fi
    
    # Start app with HTTP mapping
    HF_API_BASE="http://localhost:$HF_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run > redirect-app.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "App failed to start for redirect test"
        return 1
    fi
    
    log_info "Making Hugging Face API call that should trigger redirect..."
    curl -s "http://localhost:$APP_PORT/models/openai" > redirect-response.txt
    
    # Stop processes
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 3
    
    # Check what was recorded
    local recording_dir=$(find proxymock -name "redirect-test-*" -type d | tail -1)
    if [ -n "$recording_dir" ]; then
        log_info "Recording directory: $recording_dir"
        
        # Check if huggingface.co directory exists
        if [ -d "$recording_dir/huggingface.co" ]; then
            local hf_files=$(find "$recording_dir/huggingface.co" -name "*.md" | wc -l)
            log_info "Hugging Face files recorded: $hf_files"
            
            if [ "$hf_files" -gt 0 ]; then
                # Check if the recorded request shows the redirect
                local sample_file=$(find "$recording_dir/huggingface.co" -name "*.md" | head -1)
                if grep -q "301 Moved Permanently" "$sample_file"; then
                    log_warning "REDIRECT BYPASS DETECTED: Hugging Face API returns 301 redirect"
                    log_warning "WebClient follows redirect to https://huggingface.co, bypassing proxymock"
                    log_warning "This means the actual API call goes directly to the real API"
                    return 0  # This is expected behavior, not an error
                fi
            fi
        else
            log_warning "No huggingface.co directory found - redirect may have bypassed proxymock entirely"
        fi
    fi
    
    log_success "Redirect bypass validation completed"
    return 0
}

# Main execution
main() {
    log_info "=== COMPREHENSIVE REVERSE PROXY RECORDING TEST ==="
    
    trap cleanup EXIT
    
    test_baseline || exit 1
    test_proxymock_recording || exit 1
    test_validate_structure || exit 1
    test_mock_server || exit 1
    test_redirect_bypass_validation || exit 1
    
    log_success "=== ALL TESTS PASSED ==="
    log_info "Recording directory: $RECORDING_DIR"
    log_info "Check 'ls -la $RECORDING_DIR' to see the 3 subdirectories"
}

main "$@"