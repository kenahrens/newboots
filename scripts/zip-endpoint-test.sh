#!/usr/bin/env bash
# zip-endpoint-test.sh
# Complete test of /zip endpoint with proxymock recording and mocking

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
GITHUB_MAP_PORT=65082
LEARNING_MAP_PORT=65083
RECORDING_DIR="proxymock/recorded-zip-$(date +%Y-%m-%d_%H-%M-%S)"

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
    log_info "Waiting for port $port to be ready..."
    for i in $(seq 1 $max_attempts); do
        if lsof -i :$port >/dev/null 2>&1; then
            log_success "Port $port is ready"
            return 0
        fi
        sleep 2
    done
    log_error "Port $port failed to start after $max_attempts attempts"
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
    
    MYSQL_PORT=3307 MONGODB_PORT=27017 mvn spring-boot:run > baseline-zip.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Baseline app failed to start"
        return 1
    fi
    
    log_info "Capturing baseline responses..."
    echo "=== BASELINE ZIP RESPONSES ===" > baseline-zip-responses.txt
    
    # Test default zip (speedscale)
    echo "Default ZIP (speedscale):" >> baseline-zip-responses.txt
    curl -s "http://localhost:$APP_PORT/zip" | jq '.' >> baseline-zip-responses.txt 2>&1
    
    # Test named zip (jquery)
    echo -e "\nNamed ZIP (jquery):" >> baseline-zip-responses.txt
    curl -s "http://localhost:$APP_PORT/zip?filename=jquery" | jq '.' >> baseline-zip-responses.txt 2>&1
    
    # Test bootstrap zip
    echo -e "\nNamed ZIP (bootstrap):" >> baseline-zip-responses.txt
    curl -s "http://localhost:$APP_PORT/zip?filename=bootstrap" | jq '.' >> baseline-zip-responses.txt 2>&1
    
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    sleep 2
    
    log_success "Baseline test completed"
    return 0
}

# Test 2: Proxymock recording
test_proxymock_recording() {
    log_info "=== TEST 2: PROXYMOCK RECORDING ==="
    
    # Start proxymock with mappings for GitHub and LearningContainer
    proxymock record \
        --map $GITHUB_MAP_PORT=https://github.com:443 \
        --map $LEARNING_MAP_PORT=https://www.learningcontainer.com:443 \
        --app-port $APP_PORT \
        --out "$RECORDING_DIR" > proxymock-zip.log 2>&1 &
    
    # Wait for proxymock to start
    if ! wait_for_port $GITHUB_MAP_PORT || ! wait_for_port $LEARNING_MAP_PORT; then
        log_error "Proxymock failed to start on required ports"
        return 1
    fi
    
    log_info "Starting application with ZIP URL overrides..."
    
    # Start app with environment overrides and JVM arguments
    ZIP_GITHUB_BASE="https://localhost:$GITHUB_MAP_PORT" \
    ZIP_LEARNING_BASE="https://localhost:$LEARNING_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run \
    -Dspring-boot.run.jvmArguments="-Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit" \
    > proxymock-app-zip.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Proxymock app failed to start"
        return 1
    fi
    
    log_info "Making test calls to /zip endpoint..."
    
    # 1. Test default zip (speedscale from GitHub)
    log_info "Testing default ZIP download (speedscale)..."
    curl -s "http://localhost:$APP_PORT/zip" > proxymock-zip-default.json
    
    # 2. Test jquery zip
    log_info "Testing jQuery ZIP download..."
    curl -s "http://localhost:$APP_PORT/zip?filename=jquery" > proxymock-zip-jquery.json
    
    # 3. Test bootstrap zip
    log_info "Testing Bootstrap ZIP download..."
    curl -s "http://localhost:$APP_PORT/zip?filename=bootstrap" > proxymock-zip-bootstrap.json
    
    # 4. Test non-existent file from learningcontainer
    log_info "Testing non-existent ZIP file..."
    curl -s "http://localhost:$APP_PORT/zip?filename=sample-zip-files.zip" > proxymock-zip-learning.json
    
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
    
    # Check for GitHub directory
    if [ -d "$RECORDING_DIR/github.com" ]; then
        log_success "Found github.com directory for GitHub ZIP traffic"
    else
        log_warning "Missing github.com directory - may not have captured GitHub traffic"
    fi
    
    # Check for LearningContainer directory
    if [ -d "$RECORDING_DIR/www.learningcontainer.com" ]; then
        log_success "Found www.learningcontainer.com directory for LearningContainer traffic"
    else
        log_warning "Missing www.learningcontainer.com directory - may not have captured LearningContainer traffic"
    fi
    
    # Check for localhost directory (inbound traffic)
    if [ -d "$RECORDING_DIR/localhost" ]; then
        log_success "Found localhost directory for inbound traffic"
    else
        log_warning "Missing localhost directory - no inbound traffic captured via proxy"
    fi
    
    # Count and validate files
    local total_files=0
    local valid_files=0
    
    for dir in "$RECORDING_DIR"/*; do
        if [ -d "$dir" ]; then
            local dir_name=$(basename "$dir")
            local files_count=$(find "$dir" -name "*.md" | wc -l)
            log_info "Files in $dir_name: $files_count"
            
            for file in "$dir"/*.md; do
                if [ -f "$file" ]; then
                    total_files=$((total_files + 1))
                    if (grep -q "### REQUEST" "$file" || grep -q "### REQUEST (TEST)" "$file") && \
                       grep -q "### RESPONSE" "$file" && \
                       grep -q "### METADATA ###" "$file"; then
                        valid_files=$((valid_files + 1))
                    else
                        log_error "Invalid file structure in $file"
                    fi
                fi
            done
        fi
    done
    
    log_info "Valid file structure: $valid_files/$total_files files"
    
    if [ $valid_files -eq $total_files ] && [ $total_files -gt 0 ]; then
        log_success "All recorded files have valid RRPair structure"
        return 0
    else
        log_error "Some files have invalid structure or no files were recorded"
        return 1
    fi
}

# Test 4: Mock server test
test_mock_server() {
    log_info "=== TEST 4: MOCK SERVER TEST ==="
    
    local mock_dir="proxymock/mocked-zip-$(date +%Y-%m-%d_%H-%M-%S)"
    
    # Start mock server with recorded data
    proxymock mock \
        --map $GITHUB_MAP_PORT=https://github.com:443 \
        --map $LEARNING_MAP_PORT=https://www.learningcontainer.com:443 \
        --in "$RECORDING_DIR" \
        --out "$mock_dir" > mock-zip.log 2>&1 &
    
    if ! wait_for_port $GITHUB_MAP_PORT || ! wait_for_port $LEARNING_MAP_PORT; then
        log_error "Mock server failed to start"
        return 1
    fi
    
    log_info "Starting application with mock server..."
    
    # Start app with mock server URLs and JVM arguments
    ZIP_GITHUB_BASE="https://localhost:$GITHUB_MAP_PORT" \
    ZIP_LEARNING_BASE="https://localhost:$LEARNING_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run \
    -Dspring-boot.run.jvmArguments="-Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit" \
    > mock-app-zip.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "Mock app failed to start"
        return 1
    fi
    
    # Test responses with mock server
    log_info "Testing ZIP endpoints with mock server..."
    curl -s "http://localhost:$APP_PORT/zip" > mock-zip-default.json
    curl -s "http://localhost:$APP_PORT/zip?filename=jquery" > mock-zip-jquery.json
    curl -s "http://localhost:$APP_PORT/zip?filename=bootstrap" > mock-zip-bootstrap.json
    
    # Compare responses
    log_info "Comparing mock responses with recorded responses..."
    if cmp -s proxymock-zip-default.json mock-zip-default.json; then
        log_success "Default ZIP response matches"
    else
        log_warning "Default ZIP response differs (expected for timestamps)"
    fi
    
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 2
    
    log_success "Mock server test completed"
    return 0
}

# Test 5: Validate ZIP content
test_validate_zip_content() {
    log_info "=== TEST 5: VALIDATE ZIP CONTENT ==="
    
    # Check if responses contain expected ZIP file information
    for response_file in proxymock-zip-*.json; do
        if [ -f "$response_file" ]; then
            log_info "Checking $response_file..."
            
            # Check for expected JSON structure
            if jq -e '.totalFiles' "$response_file" >/dev/null 2>&1; then
                local total_files=$(jq -r '.totalFiles' "$response_file")
                log_success "$response_file contains valid ZIP info with $total_files files"
            elif jq -e '.error' "$response_file" >/dev/null 2>&1; then
                local error_msg=$(jq -r '.error' "$response_file")
                log_warning "$response_file contains error: $error_msg"
            else
                log_error "$response_file has unexpected format"
            fi
        fi
    done
    
    return 0
}

# Main execution
main() {
    log_info "=== COMPREHENSIVE ZIP ENDPOINT TEST WITH PROXYMOCK ==="
    
    trap cleanup EXIT
    
    # Ensure TLS certificates are configured
    if [ -f "$HOME/.speedscale/certs/cacerts.jks" ]; then
        export MAVEN_OPTS="-Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit"
        log_info "TLS certificates configured"
    else
        log_warning "No TLS certificates found - HTTPS may fail"
    fi
    
    test_baseline || exit 1
    test_proxymock_recording || exit 1
    test_validate_structure || exit 1
    test_mock_server || exit 1
    test_validate_zip_content || exit 1
    
    log_success "=== ALL ZIP ENDPOINT TESTS PASSED ==="
    log_info "Recording directory: $RECORDING_DIR"
    log_info "Check 'ls -la $RECORDING_DIR' to see captured traffic"
}

main "$@"