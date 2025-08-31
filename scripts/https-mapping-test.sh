#!/usr/bin/env bash
# https-mapping-test.sh
# Test to demonstrate that HTTPS mapping avoids redirect bypass issue

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
RECORDING_DIR="proxymock/https-mapping-test-$(date +%Y-%m-%d_%H-%M-%S)"

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
    log_info "=== HTTPS MAPPING SOLUTION TEST ==="
    log_info "This test demonstrates that HTTPS mapping avoids the redirect bypass issue"
    
    trap cleanup EXIT
    
    # Start proxymock with HTTPS mapping for Hugging Face
    log_info "Starting proxymock with HTTPS mapping for Hugging Face..."
    proxymock record \
        --map $HF_MAP_PORT=https://huggingface.co:443 \
        --app-port $APP_PORT \
        --out "$RECORDING_DIR" > https-proxymock.log 2>&1 &
    
    if ! wait_for_port $HF_MAP_PORT; then
        log_error "Proxymock failed to start for HTTPS mapping test"
        exit 1
    fi
    
    # Start app with HTTPS mapping
    log_info "Starting application with HTTPS mapping for Hugging Face..."
    HF_API_BASE="https://localhost:$HF_MAP_PORT" \
    MYSQL_PORT=3307 MONGODB_PORT=27017 \
    mvn spring-boot:run > https-app.log 2>&1 &
    
    if ! wait_for_app; then
        log_error "App failed to start for HTTPS mapping test"
        exit 1
    fi
    
    log_info "Making Hugging Face API call with HTTPS mapping..."
    curl -s "http://localhost:$APP_PORT/models/openai" > https-response.txt
    
    # Stop processes
    pkill -f "spring-boot:run" >/dev/null 2>&1 || true
    pkill -f "proxymock" >/dev/null 2>&1 || true
    sleep 3
    
    # Check what was recorded
    log_info "Analyzing HTTPS mapping results..."
    if [ -d "$RECORDING_DIR" ]; then
        log_info "Recording directory: $RECORDING_DIR"
        
        # Check if huggingface.co directory exists
        if [ -d "$RECORDING_DIR/huggingface.co" ]; then
            local hf_files=$(find "$RECORDING_DIR/huggingface.co" -name "*.md" | wc -l)
            log_info "Hugging Face files recorded: $hf_files"
            
            if [ "$hf_files" -gt 0 ]; then
                # Check if the recorded request shows actual API data (not redirect)
                local sample_file=$(find "$RECORDING_DIR/huggingface.co" -name "*.md" | head -1)
                if grep -q "301 Moved Permanently" "$sample_file"; then
                    log_warning "Still getting redirect - HTTPS mapping may not be working"
                elif grep -q "openai/gpt" "$sample_file"; then
                    log_success "SUCCESS: HTTPS mapping captured actual API data"
                    log_success "No redirect bypass - proxymock captured the full API call"
                else
                    log_info "Response captured but content unclear"
                fi
            fi
        else
            log_warning "No huggingface.co directory found - HTTPS mapping may not be working"
        fi
        
        # Check application logs for successful API call
        if grep -q "Successfully retrieved OpenAI models from Hugging Face" https-app.log; then
            log_success "Application logs show successful API call with HTTPS mapping"
        fi
    else
        log_error "No recording directory found"
        exit 1
    fi
    
    log_success "HTTPS mapping solution test completed"
    log_info "This demonstrates the recommended approach for APIs that use redirects"
}

main "$@"
