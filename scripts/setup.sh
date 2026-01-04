#!/bin/bash
#==============================================================================
# AEGIS Protocol v3.1 - Setup Script
#
# 새 프로젝트에 AEGIS를 설치하는 스크립트
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/minjaebaaak/aegis-protocol/master/scripts/setup.sh | bash -s -- /path/to/project
#   또는
#   ./setup.sh /path/to/project
#==============================================================================

set -euo pipefail

#==============================================================================
# Configuration
#==============================================================================

AEGIS_REPO="https://github.com/minjaebaaak/aegis-protocol.git"
AEGIS_BRANCH="master"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#==============================================================================
# Functions
#==============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              AEGIS Protocol v3.1 - Setup                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✅ ${NC}$1"; }
print_warning() { echo -e "${YELLOW}⚠️  ${NC}$1"; }
print_error() { echo -e "${RED}❌ ${NC}$1"; }

show_usage() {
    cat << EOF
Usage: $0 <project-path> [OPTIONS]

Arguments:
    project-path    Path to your project directory

Options:
    --minimal       Install only essential files
    --full          Install all files including examples
    -h, --help      Show this help

Examples:
    $0 /path/to/my-project
    $0 . --minimal
    curl -fsSL https://raw.githubusercontent.com/minjaebaaak/aegis-protocol/master/scripts/setup.sh | bash -s -- /path/to/project

AEGIS Protocol v3.1
EOF
}

#==============================================================================
# Main
#==============================================================================

main() {
    print_header

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local project_path=$1
    local mode="standard"
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            --minimal) mode="minimal"; shift ;;
            --full) mode="full"; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) print_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    # Validate project path
    if [[ ! -d "$project_path" ]]; then
        print_error "Project directory not found: $project_path"
        exit 1
    fi

    cd "$project_path"
    print_info "Installing AEGIS to: $(pwd)"

    # Create temp directory for clone
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Clone AEGIS repo
    print_info "Downloading AEGIS Protocol..."
    git clone --depth 1 --branch "$AEGIS_BRANCH" "$AEGIS_REPO" "$temp_dir" 2>/dev/null

    # Create directories
    mkdir -p .0 scripts

    # Copy files based on mode
    print_info "Installing files (mode: $mode)..."

    # Essential files (always installed)
    cp "$temp_dir/CLAUDE.md.template" ./CLAUDE.md.template
    cp "$temp_dir/aegis.config.example.js" ./aegis.config.example.js
    cp "$temp_dir/.0/AEGIS_PROTOCOL.md" ./.0/AEGIS_PROTOCOL.md
    cp "$temp_dir/scripts/aegis-validate.sh" ./scripts/aegis-validate.sh
    cp "$temp_dir/scripts/rollback.sh" ./scripts/rollback.sh

    # Make scripts executable
    chmod +x ./scripts/*.sh

    if [[ "$mode" != "minimal" ]]; then
        # Standard files
        cp "$temp_dir/.npmrc" ./.npmrc 2>/dev/null || true
        cp "$temp_dir/scripts/deploy.sh.template" ./scripts/deploy.sh.template
    fi

    if [[ "$mode" == "full" ]]; then
        # Full installation
        cp "$temp_dir/LICENSE" ./LICENSE 2>/dev/null || true
    fi

    # Add to .gitignore if exists
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "aegis.config.js" .gitignore; then
            echo -e "\n# AEGIS Protocol\naeigs.config.js" >> .gitignore
            print_info "Updated .gitignore"
        fi
    fi

    echo ""
    print_success "AEGIS Protocol installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Copy and customize config:"
    echo "     cp aegis.config.example.js aegis.config.js"
    echo ""
    echo "  2. Copy and customize CLAUDE.md:"
    echo "     cp CLAUDE.md.template CLAUDE.md"
    echo "     # Edit CLAUDE.md and replace {{PLACEHOLDERS}}"
    echo ""
    echo "  3. Customize deploy script:"
    echo "     cp scripts/deploy.sh.template scripts/deploy.sh"
    echo "     # Edit scripts/deploy.sh and replace {{PLACEHOLDERS}}"
    echo ""
    echo "  4. Run validation:"
    echo "     ./scripts/aegis-validate.sh --build"
    echo ""
}

main "$@"
