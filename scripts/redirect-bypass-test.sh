#!/usr/bin/env bash
# redirect-bypass-test.sh
# Test to demonstrate that WebClient follows 301 redirects, bypassing proxymock

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
APP_PORT=8080
HF_MAP_PORT=65081
RECORDING_DIR="proxymock/redirect-bypass-test-$(date +%Y-%m-%d_%H-%M-%S)"

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

main() {
    log_info "=== REDIRECT BYPASS VALIDATION TEST ==="
    log_info "This test demonstrates that WebClient follows 301 redirects, bypassing proxymock"
    
    trap cleanup EXIT
    
    # Start proxymock with HTTP mapping for Hugging Face
    log_info "Starting proxymock with HTTP mapping for Hugging Face..."
    proxymock record \
        --map $HF_MAP_PORT=http://huggingface.co:80 \
        --app-port $APP_PORT \
        --out "$RECORDING_DIR" > redirect-proxymock.log 2>&1 &
    
    if ! wait_for_port $HF_MAP_PORT; then
        log_error "Proxymock failed to start for redirect test"
        exit 1
    fi
    
    # Start app with HTTP mapping
    log_info "Starting application with HTTP mapping for Hugging Face..."
    HF_API_BASE="http://localhost:$HF_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run > redirect-app.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "App failed to start for redirect test"
        exit 1
    fi
    
    log_info "Making Hugging Face API call that should trigger redirect..."
    curl -s "http://localhost:$APP_PORT/models/openai" > redirect-response.txt
    
    # Stop processes
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 3
    
    # Check what was recorded
    log_info "Analyzing recording results..."
    if [ -d "$RECORDING_DIR" ]; then
        log_info "Recording directory: $RECORDING_DIR"
        
        # Check if huggingface.co directory exists
        if [ -d "$RECORDING_DIR/huggingface.co" ]; then
            local hf_files=$(find "$RECORDING_DIR/huggingface.co" -name "*.md" | wc -l)
            log_info "Hugging Face files recorded: $hf_files"
            
            if [ "$hf_files" -gt 0 ]; then
                # Check if the recorded request shows the redirect
                local sample_file=$(find "$RECORDING_DIR/huggingface.co" -name "*.md" | head -1)
                if grep -q "301 Moved Permanently" "$sample_file"; then
                    log_warning "REDIRECT BYPASS DETECTED: Hugging Face API returns 301 redirect"
                    log_warning "WebClient follows redirect to https://huggingface.co, bypassing proxymock"
                    log_warning "This means the actual API call goes directly to the real API"
                    log_warning "Only the initial HTTP request and 301 response are captured"
                    
                    # Show the redirect response
                    log_info "Redirect response captured:"
                    grep -A 10 "301 Moved Permanently" "$sample_file" | head -5
                fi
            fi
        else
            log_warning "No huggingface.co directory found - redirect may have bypassed proxymock entirely"
        fi
        
        # Check application logs for successful API call
        if grep -q "Successfully retrieved OpenAI models from Hugging Face" redirect-app.log; then
            log_warning "Application logs show successful API call - this confirms redirect bypass"
            log_warning "The WebClient followed the 301 redirect to https://huggingface.co"
            log_warning "The actual API call went directly to the real API, not through proxymock"
        fi
    else
        log_error "No recording directory found"
        exit 1
    fi
    
    log_success "Redirect bypass validation completed"
    log_info "This demonstrates a limitation of the map approach with APIs that use redirects"
}

main "$@"
