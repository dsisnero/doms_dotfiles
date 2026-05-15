#!/bin/bash
#
# Standalone script to clean up AppleDouble files in git repositories on ExFAT
# Run this manually when git shows corruption errors
#

set -e

# Simple logging functions
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is for macOS only"
    exit 1
fi

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    return 0
}

# Check filesystem type
get_filesystem_type() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        dir="."
    fi

    if command -v diskutil >/dev/null 2>&1; then
        fs_info=$(diskutil info "$dir" 2>/dev/null | grep -i "File System Personality" || true)
        if [[ -n "$fs_info" ]]; then
            echo "$fs_info" | sed 's/.*File System Personality:[[:space:]]*//'
            return 0
        fi
    fi

    echo "unknown"
}

# Clean AppleDouble files
clean_appledouble_files() {
    local repo_dir="$1"
    local dry_run="${2:-false}"
    local total_count=0

    # Clean ._* files
    if [[ "$dry_run" == "true" ]]; then
        count1=$(find "$repo_dir/.git" -name "._*" -type f 2>/dev/null | wc -l | tr -d ' ')
    else
        count1=$(find "$repo_dir/.git" -name "._*" -type f -delete 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [[ $count1 -gt 0 ]]; then
        log_warn "Found $count1 ._* files"
        total_count=$((total_count + count1))
    fi

    # Clean .DS_Store files
    if [[ "$dry_run" == "true" ]]; then
        count2=$(find "$repo_dir/.git" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')
    else
        count2=$(find "$repo_dir/.git" -name ".DS_Store" -type f -delete 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [[ $count2 -gt 0 ]]; then
        log_warn "Found $count2 .DS_Store files"
        total_count=$((total_count + count2))
    fi

    # Clean corrupted refs
    for ref_type in heads remotes tags; do
        ref_dir="$repo_dir/.git/refs/$ref_type"
        if [[ -d "$ref_dir" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                ref_count=$(find "$ref_dir" -name "._*" -type f 2>/dev/null | wc -l | tr -d ' ')
            else
                ref_count=$(find "$ref_dir" -name "._*" -type f -delete 2>/dev/null | wc -l | tr -d ' ')
            fi

            if [[ $ref_count -gt 0 ]]; then
                log_warn "Cleaned $ref_count AppleDouble files from refs/$ref_type"
                total_count=$((total_count + ref_count))
            fi
        fi
    done

    echo "$total_count"
}

# Main function
main() {
    local dry_run=false
    local repair=false
    local repo_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            --repair|-r)
                repair=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --dry-run, -n    Show what would be cleaned without deleting"
                echo "  --repair, -r     Attempt to repair git repository after cleaning"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                if [[ -z "$repo_dir" ]]; then
                    repo_dir="$1"
                else
                    log_error "Unknown argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Determine repository directory
    if [[ -z "$repo_dir" ]]; then
        if check_git_repo; then
            repo_dir="$(git rev-parse --show-toplevel)"
        else
            log_error "Please run this script from within a git repository or specify the path"
            exit 1
        fi
    fi

    if [[ ! -d "$repo_dir/.git" ]]; then
        log_error "Not a git repository: $repo_dir"
        exit 1
    fi

    # Check filesystem
    fs_type=$(get_filesystem_type "$repo_dir")
    log_info "Filesystem type: $fs_type"

    if echo "$fs_type" | grep -qi "exfat"; then
        log_warn "WARNING: Repository is on ExFAT filesystem"
        log_warn "ExFAT doesn't properly support macOS metadata and can corrupt git repositories"
        log_warn "For long-term use, consider moving to APFS or HFS+ filesystem"
    fi

    # Clean AppleDouble files
    log_info "Starting cleanup..."
    local count
    count=$(clean_appledouble_files "$repo_dir" "$dry_run" 2>&1 | tail -1)

    if [[ $count -gt 0 ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_warn "DRY RUN: Would remove $count AppleDouble/metadata files"
        else
            log_warn "Removed $count AppleDouble/metadata files"

            # Run repair if requested
            if [[ "$repair" == "true" ]]; then
                log_info "Attempting to repair git repository..."
                (cd "$repo_dir" && git fsck --full --strict 2>/dev/null || true)
                (cd "$repo_dir" && git gc --aggressive --prune=now 2>/dev/null || true)
            fi

            log_info "Cleanup complete. You may want to run:"
            log_info "  git fsck --full --strict"
            log_info "  git gc --aggressive --prune=now"
        fi
    else
        log_info "No AppleDouble files found"
    fi
}

# Run main function
main "$@"