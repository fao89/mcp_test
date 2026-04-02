#!/bin/bash

# Script to process all directories with MCP client
# Sends input.md along with clusterversion.yaml and clusteroperators.yaml as attachments

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_CLIENT="$SCRIPT_DIR/mcp-client.sh"

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

# Function to create enhanced query with file attachments
create_query_with_attachments() {
    local dir="$1"
    local input_file="$dir/input.md"
    local clusterversion_file="$dir/clusterversion.yaml"
    local clusteroperators_file="$dir/clusteroperators.yaml"

    # Check if all required files exist
    if [[ ! -f "$input_file" ]]; then
        log_error "Missing input.md in $dir"
        return 1
    fi

    if [[ ! -f "$clusterversion_file" ]]; then
        log_error "Missing clusterversion.yaml in $dir"
        return 1
    fi

    if [[ ! -f "$clusteroperators_file" ]]; then
        log_error "Missing clusteroperators.yaml in $dir"
        return 1
    fi

    # Read file contents
    local input_content
    local clusterversion_content
    local clusteroperators_content

    input_content=$(cat "$input_file")
    clusterversion_content=$(cat "$clusterversion_file")
    clusteroperators_content=$(cat "$clusteroperators_file")

    # Create enhanced query that includes file contents as context
    cat << EOF
$input_content

<attachments>
<attachment name="clusterversion.yaml" type="yaml">
$clusterversion_content
</attachment>

<attachment name="clusteroperators.yaml" type="yaml">
$clusteroperators_content
</attachment>
</attachments>
EOF
}

# Function to process a single directory
process_directory() {
    local dir="$1"
    log_info "Processing directory: $dir"

    # Create the enhanced query
    local query
    query=$(create_query_with_attachments "$dir")
    if [[ $? -ne 0 ]]; then
        log_error "Failed to create query for $dir"
        return 1
    fi

    # Send the query using mcp-client.sh in quiet mode and capture output
    log_info "Sending query to MCP service for $dir..."
    local response
    response=$("$MCP_CLIENT" --quiet query "$query" 2>/dev/null)

    if [[ $? -eq 0 && -n "$response" ]]; then
        # Extract just the response content from JSON and save to output.md
        local output_file="$dir/output.md"

        # Check if response is JSON and extract the response field
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -r '.response // .rawResponse // .' > "$output_file"
            log_success "Response content saved to $output_file"

            # Display analysis summary
            log_info "Analysis summary:"
            echo "$response" | jq -r '.response // .rawResponse // .' 2>/dev/null | head -20
        else
            # If not JSON, save as-is
            echo "$response" > "$output_file"
            log_success "Response saved to $output_file"
        fi
    else
        log_error "Failed to get response for $dir"
        return 1
    fi

    echo
}

# Main execution
main() {
    log_info "Starting batch processing of directories with MCP client"
    echo

    # Check if mcp-client.sh exists
    if [[ ! -f "$MCP_CLIENT" ]]; then
        log_error "MCP client script not found at $MCP_CLIENT"
        exit 1
    fi

    # Make sure the MCP client is executable
    chmod +x "$MCP_CLIENT"

    # Get all directories to process (excluding samples, .git, and current directory)
    # Only process directories that have all required files
    local all_dirs=($(find "$SCRIPT_DIR" -maxdepth 1 -type d ! -name "." ! -name ".git" ! -name "samples" ! -name ".claude" | sort))
    local dirs=()

    for dir in "${all_dirs[@]}"; do
        if [[ -f "$dir/input.md" && -f "$dir/clusterversion.yaml" && -f "$dir/clusteroperators.yaml" ]]; then
            dirs+=("$dir")
        fi
    done

    if [[ ${#dirs[@]} -eq 0 ]]; then
        log_error "No directories found to process"
        exit 1
    fi

    log_info "Found ${#dirs[@]} directories to process"

    # Initialize MCP client (this will set up port forwarding, etc.)
    log_info "Initializing MCP client connection..."
    "$MCP_CLIENT" health >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log_error "Failed to initialize MCP client connection"
        exit 1
    fi

    local success_count=0
    local total_count=${#dirs[@]}

    # Process each directory
    for dir in "${dirs[@]}"; do
        if process_directory "$dir"; then
            ((success_count++))
        fi
    done

    echo
    log_info "Processing complete: $success_count/$total_count directories processed successfully"

    if [[ $success_count -eq $total_count ]]; then
        log_success "All directories processed successfully!"
    else
        log_error "Some directories failed to process"
        exit 1
    fi
}

# Run main function
main "$@"