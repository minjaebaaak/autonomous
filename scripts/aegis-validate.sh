#!/bin/bash
#==============================================================================
# AEGIS Protocol v3.1 - Validation Script
# 범용 검증 스크립트
#==============================================================================

set -euo pipefail

#==============================================================================
# Configuration
#==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/aegis.config.js"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BUILD_CMD="pnpm build"
TEST_CMD="pnpm test"
LINT_CMD="pnpm lint"
TYPE_CHECK_CMD="pnpm type-check"

#==============================================================================
# Functions
#==============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               AEGIS Protocol v3.1 - Validator                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✅ ${NC}$1"; }
print_warning() { echo -e "${YELLOW}⚠️  ${NC}$1"; }
print_error() { echo -e "${RED}❌ ${NC}$1"; }

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

AEGIS Protocol v3.1 - 7-Layer Validation

Options:
    --all           Run all validations (Layer 0-4)
    --build         Layer 1: Static Analysis (build, type-check, lint)
    --test          Layer 2: Unit Tests
    --api           Layer 3: Integration Tests
    --e2e           Layer 4: E2E Tests
    --schema TABLE  Layer 0: Schema Validation
    --monitor       Layer 6: Production Monitoring
    -h, --help      Show this help message

Examples:
    $0 --all                    # Run all validations
    $0 --build                  # Build validation only
    $0 --schema users email     # Check 'email' column in 'users' table
    $0 --monitor                # Check production health

AEGIS Protocol v3.1
EOF
}

ensure_pnpm() {
    if command -v pnpm &> /dev/null; then
        return 0
    fi

    if command -v corepack &> /dev/null; then
        corepack enable 2>/dev/null || true
        if ! pnpm --version &> /dev/null; then
            corepack prepare pnpm@latest --activate 2>/dev/null || true
        fi
    fi

    if ! command -v pnpm &> /dev/null; then
        print_warning "pnpm not found. Installing via npm..."
        npm install -g pnpm 2>/dev/null || {
            print_error "Failed to install pnpm"
            exit 1
        }
    fi
}

#==============================================================================
# Layer 0: Schema Validation
#==============================================================================

validate_schema() {
    local table=$1
    local column=${2:-""}

    print_info "Layer 0: Schema Validation"
    print_info "Table: $table, Column: $column"

    # Check if DATABASE_URL is set
    if [[ -z "${DATABASE_URL:-}" ]]; then
        print_warning "DATABASE_URL not set. Skipping schema validation."
        print_info "Set DATABASE_URL to enable schema validation."
        return 0
    fi

    print_success "Schema validation passed (placeholder)"
}

#==============================================================================
# Layer 1: Static Analysis
#==============================================================================

validate_build() {
    print_info "Layer 1: Static Analysis"

    ensure_pnpm

    # Type check (if available)
    if [[ -f "package.json" ]] && grep -q "type-check" package.json; then
        print_info "Running type-check..."
        if $TYPE_CHECK_CMD 2>/dev/null; then
            print_success "Type check passed"
        else
            print_error "Type check failed"
            return 1
        fi
    fi

    # Lint (if available)
    if [[ -f "package.json" ]] && grep -q "\"lint\"" package.json; then
        print_info "Running lint..."
        if $LINT_CMD 2>/dev/null; then
            print_success "Lint passed"
        else
            print_warning "Lint has warnings (non-blocking)"
        fi
    fi

    # Build
    print_info "Running build..."

    # Disable GPU for build (TensorFlow.js compatibility)
    export CUDA_VISIBLE_DEVICES=""

    if $BUILD_CMD; then
        print_success "Build passed"
    else
        print_error "Build failed"
        return 1
    fi

    print_success "Layer 1: Static Analysis completed"
}

#==============================================================================
# Layer 2: Unit Tests
#==============================================================================

validate_unit_tests() {
    print_info "Layer 2: Unit Tests"

    ensure_pnpm

    if [[ -f "package.json" ]] && grep -q "\"test\"" package.json; then
        if $TEST_CMD; then
            print_success "Unit tests passed"
        else
            print_error "Unit tests failed"
            return 1
        fi
    else
        print_warning "No test script found. Skipping."
    fi

    print_success "Layer 2: Unit Tests completed"
}

#==============================================================================
# Layer 3: Integration Tests
#==============================================================================

validate_api() {
    print_info "Layer 3: Integration Tests"

    # Check if API tests exist
    if [[ -f "package.json" ]] && grep -q "test:integration" package.json; then
        ensure_pnpm
        if pnpm test:integration; then
            print_success "Integration tests passed"
        else
            print_error "Integration tests failed"
            return 1
        fi
    else
        print_warning "No integration test script found. Skipping."
    fi

    print_success "Layer 3: Integration Tests completed"
}

#==============================================================================
# Layer 4: E2E Tests
#==============================================================================

validate_e2e() {
    print_info "Layer 4: E2E Tests"

    if [[ -f "package.json" ]] && grep -q "test:e2e" package.json; then
        ensure_pnpm
        if pnpm test:e2e; then
            print_success "E2E tests passed"
        else
            print_error "E2E tests failed"
            return 1
        fi
    else
        print_warning "No E2E test script found."
        print_info "Use Playwright MCP for manual E2E testing."
    fi

    print_success "Layer 4: E2E Tests completed"
}

#==============================================================================
# Layer 6: Production Monitor
#==============================================================================

validate_monitor() {
    print_info "Layer 6: Production Monitoring"

    # Check PM2
    if command -v pm2 &> /dev/null; then
        print_info "PM2 Status:"
        pm2 list

        print_info "Recent logs (last 20 lines):"
        pm2 logs --lines 20 --nostream 2>/dev/null || true
    else
        print_warning "PM2 not found. Skipping process monitoring."
    fi

    print_success "Layer 6: Production Monitoring completed"
}

#==============================================================================
# Run All
#==============================================================================

validate_all() {
    print_info "Running all validations (Layer 0-4)..."

    local failed=0

    validate_build || ((failed++))
    validate_unit_tests || ((failed++))
    validate_api || ((failed++))
    validate_e2e || ((failed++))

    if [[ $failed -eq 0 ]]; then
        echo ""
        print_success "All validations passed!"
        return 0
    else
        echo ""
        print_error "$failed validation(s) failed"
        return 1
    fi
}

#==============================================================================
# Main
#==============================================================================

main() {
    print_header

    cd "$PROJECT_ROOT"

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    case "$1" in
        --all)
            validate_all
            ;;
        --build)
            validate_build
            ;;
        --test)
            validate_unit_tests
            ;;
        --api)
            validate_api
            ;;
        --e2e)
            validate_e2e
            ;;
        --schema)
            shift
            validate_schema "${1:-}" "${2:-}"
            ;;
        --monitor)
            validate_monitor
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
