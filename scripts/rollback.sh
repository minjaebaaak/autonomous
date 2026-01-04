#!/bin/bash
#==============================================================================
# AEGIS Protocol v3.1 - Rollback Script
#==============================================================================

set -euo pipefail

#==============================================================================
# Configuration
#==============================================================================

BACKUP_DIR=""
DRY_RUN=false

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
    echo -e "${BLUE}║              AEGIS Protocol v3.1 - Rollback                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✅ ${NC}$1"; }
print_warning() { echo -e "${YELLOW}⚠️  ${NC}$1"; }
print_error() { echo -e "${RED}❌ ${NC}$1"; }

show_usage() {
    cat << EOF
Usage: $0 <backup-directory> [OPTIONS]

Arguments:
    backup-directory    Path to backup (e.g., backups/20241028_211630)

Options:
    -d, --dry-run       Preview without changes
    -h, --help          Show this help

Examples:
    $0 backups/20241028_211630
    $0 backups/20241028_211630 --dry-run

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
        print_info "Installing pnpm..."
        npm install -g pnpm 2>/dev/null || {
            print_error "Failed to install pnpm"
            exit 1
        }
    fi
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        print_error "Backup directory required"
        show_usage
        exit 1
    fi

    BACKUP_DIR=$1
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run) DRY_RUN=true; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) print_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

validate_backup() {
    print_info "Validating backup..."

    # Handle compressed backups
    if [[ ! -d "$BACKUP_DIR" ]] && [[ -f "${BACKUP_DIR}.tar.gz" ]]; then
        print_info "Found compressed backup: ${BACKUP_DIR}.tar.gz"

        if [[ "$DRY_RUN" != "true" ]]; then
            print_info "Extracting backup..."
            tar -xzf "${BACKUP_DIR}.tar.gz" -C "$(dirname "$BACKUP_DIR")"
        fi
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi

    if [[ ! -f "$BACKUP_DIR/package.json" ]]; then
        print_error "Invalid backup: package.json not found"
        exit 1
    fi

    print_success "Backup validated: $BACKUP_DIR"
}

confirm_rollback() {
    print_warning "This will restore files from backup: $BACKUP_DIR"
    print_warning "Current files will be overwritten!"
    echo ""
    read -p "Continue with rollback? (yes/no): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        print_info "Rollback cancelled"
        exit 0
    fi
}

restore_files() {
    print_info "Restoring files from backup..."

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would restore files from: $BACKUP_DIR"
        return 0
    fi

    rsync -av --delete \
        --exclude='node_modules' \
        --exclude='.next' \
        --exclude='backups' \
        --exclude='logs' \
        "$BACKUP_DIR/" ./ > /dev/null 2>&1

    print_success "Files restored"
}

reinstall_deps() {
    print_info "Reinstalling dependencies..."

    ensure_pnpm

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would run: pnpm install"
        return 0
    fi

    if ! pnpm install > /dev/null 2>&1; then
        print_error "pnpm install failed"
        exit 1
    fi

    print_success "Dependencies reinstalled"
}

rebuild_app() {
    print_info "Rebuilding application..."

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would run: pnpm build"
        return 0
    fi

    rm -rf .next

    if ! pnpm build > /dev/null 2>&1; then
        print_error "Build failed"
        exit 1
    fi

    print_success "Application rebuilt"
}

restart_services() {
    print_info "Restarting PM2 processes..."

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would run: pm2 restart all"
        return 0
    fi

    if command -v pm2 &> /dev/null; then
        pm2 restart all
        print_success "PM2 processes restarted"
    else
        print_warning "PM2 not found - skipping process restart"
    fi
}

#==============================================================================
# Main
#==============================================================================

main() {
    print_header
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    validate_backup

    if [[ "$DRY_RUN" != "true" ]]; then
        confirm_rollback
    fi

    restore_files
    reinstall_deps
    rebuild_app
    restart_services

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY-RUN completed - No changes made"
    else
        print_success "Rollback completed successfully!"
    fi
    echo ""
}

main "$@"
