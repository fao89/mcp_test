#!/bin/bash

# Script to process all directories with MCP client
# Uses process_single_dir.sh to process each directory

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SINGLE_DIR_PROCESSOR="$SCRIPT_DIR/process_single_dir.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Main execution
main() {
    log_info "Starting batch processing of all directories with MCP client"
    echo

    # Check if process_single_dir.sh exists
    if [[ ! -f "$SINGLE_DIR_PROCESSOR" ]]; then
        log_error "Single directory processor script not found at $SINGLE_DIR_PROCESSOR"
        exit 1
    fi

    # Make sure the processor script is executable
    chmod +x "$SINGLE_DIR_PROCESSOR"

    # Get all valid directories (those with required files)
    local dirs=()
    for candidate_dir in no-updates precheck precheck-specific progress troubleshoot; do
        if [[ -d "$SCRIPT_DIR/$candidate_dir" ]]; then
            local input_file="$SCRIPT_DIR/$candidate_dir/input.md"
            local clusterversion_file="$SCRIPT_DIR/$candidate_dir/clusterversion.yaml"
            local clusteroperators_file="$SCRIPT_DIR/$candidate_dir/clusteroperators.yaml"

            if [[ -f "$input_file" && -f "$clusterversion_file" && -f "$clusteroperators_file" ]]; then
                dirs+=("$candidate_dir")
            else
                log_warning "Skipping $candidate_dir - missing required files"
            fi
        fi
    done

    if [[ ${#dirs[@]} -eq 0 ]]; then
        log_error "No valid directories found to process"
        exit 1
    fi

    log_info "Found ${#dirs[@]} directories to process: ${dirs[*]}"
    echo

    local success_count=0
    local total_count=${#dirs[@]}
    local failed_dirs=()

    # Process each directory using the single directory processor
    for dir in "${dirs[@]}"; do
        echo "=================================="
        log_info "Processing directory: $dir (${success_count}/$total_count completed)"
        echo

        if "$SINGLE_DIR_PROCESSOR" "$dir"; then
            ((success_count++))
            log_success "✓ $dir completed successfully"
        else
            failed_dirs+=("$dir")
            log_error "✗ $dir failed"
        fi

        echo
    done

    # Final summary
    echo "=================================="
    log_info "BATCH PROCESSING SUMMARY"
    echo "=================================="

    if [[ $success_count -eq $total_count ]]; then
        log_success "All $total_count directories processed successfully!"
        echo
        log_info "Processed directories:"
        for dir in "${dirs[@]}"; do
            echo "  ✅ $dir"
        done
    else
        local failed_count=${#failed_dirs[@]}
        log_warning "$success_count/$total_count directories processed successfully"
        echo

        if [[ $success_count -gt 0 ]]; then
            log_success "Successfully processed:"
            for dir in "${dirs[@]}"; do
                if [[ ! " ${failed_dirs[*]} " =~ " $dir " ]]; then
                    echo "  ✅ $dir"
                fi
            done
            echo
        fi

        if [[ $failed_count -gt 0 ]]; then
            log_error "Failed directories:"
            for dir in "${failed_dirs[@]}"; do
                echo "  ❌ $dir"
            done
            echo
        fi

        exit 1
    fi

    echo
    log_info "All output.md files have been generated with MCP analysis responses."
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat << EOF
Batch MCP Directory Processor

USAGE:
    $0

DESCRIPTION:
    Processes all valid directories with MCP client by calling process_single_dir.sh
    for each directory that contains the required files:
    - input.md
    - clusterversion.yaml
    - clusteroperators.yaml

DIRECTORIES:
    The script will automatically discover and process these directories:
    - no-updates
    - precheck
    - precheck-specific
    - progress
    - troubleshoot

    The 'samples' directory is always excluded from processing.

OUTPUT:
    Each directory will have its output.md file updated with the MCP analysis response.

DEPENDENCIES:
    - process_single_dir.sh (for individual directory processing)
    - mcp-client.sh (for MCP service communication)
    - All required tools: oc, curl, jq

EXAMPLES:
    $0                    # Process all valid directories
    $0 --help            # Show this help message
EOF
    exit 0
fi

# Run main function
main "$@"