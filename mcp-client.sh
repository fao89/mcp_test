#!/bin/bash

# MCP Client for OpenShift Lightspeed Service
# Finds the lightspeed service pod and provides easy interaction with the MCP API

set -e

# Configuration
NAMESPACE="openshift-lightspeed"
POD_LABEL="app.kubernetes.io/name=lightspeed-service-api"
LOCAL_PORT="9003"
REMOTE_PORT="8443"
TEMP_DIR="/tmp/mcp-client"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global quiet mode flag
QUIET_MODE=false

# Logging functions
log_info() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${BLUE}ℹ️  $1${NC}" >&2
    fi
}

log_success() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${GREEN}✅ $1${NC}" >&2
    fi
}

log_warning() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${YELLOW}⚠️  $1${NC}" >&2
    fi
}

log_error() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${RED}❌ $1${NC}" >&2
    fi
}

# Create temp directory
mkdir -p "$TEMP_DIR"

# Cleanup function
cleanup() {
    if [[ "$QUIET_MODE" != "true" ]]; then
        log_info "Cleaning up..."
    fi
    rm -rf "$TEMP_DIR" 2>/dev/null || true

    # Kill port forward if we started it
    if [[ -n "$PORT_FORWARD_PID" ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            log_info "Stopping port forward (PID: $PORT_FORWARD_PID)..."
        fi
        kill "$PORT_FORWARD_PID" 2>/dev/null || true
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Find lightspeed service pod
find_lightspeed_pod() {
    log_info "Looking for running pod with label $POD_LABEL in namespace $NAMESPACE..."

    # Get running pods only
    POD_NAME=$(oc get pods -n "$NAMESPACE" -l "$POD_LABEL" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [[ -z "$POD_NAME" ]]; then
        log_error "No running pod found with label $POD_LABEL in namespace $NAMESPACE"
        exit 1
    fi

    log_success "Found running pod: $POD_NAME"

    # Double-check pod status
    POD_STATUS=$(oc get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
    log_info "Pod status: $POD_STATUS"

    if [[ "$POD_STATUS" != "Running" ]]; then
        log_error "Pod $POD_NAME is not running (status: $POD_STATUS)"
        exit 1
    fi
}

# Get authentication token
get_auth_token() {
    log_info "Getting authentication token..."

    TOKEN=$(oc whoami -t 2>/dev/null)

    if [[ -z "$TOKEN" ]]; then
        log_error "Failed to get authentication token"
        exit 1
    fi

    log_success "Token obtained (${TOKEN:0:10}...)"
}

# Check if port forwarding is active
check_port_forward() {
    if curl -k -s --max-time 2 "https://localhost:$LOCAL_PORT/health" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Setup port forwarding
setup_port_forward() {
    if check_port_forward; then
        log_success "Port forwarding already active on localhost:$LOCAL_PORT"
        return 0
    fi

    log_info "Setting up port forward: localhost:$LOCAL_PORT -> $POD_NAME:$REMOTE_PORT"

    # Start port forward in background
    oc port-forward -n "$NAMESPACE" "pod/$POD_NAME" "$LOCAL_PORT:$REMOTE_PORT" >/dev/null 2>&1 &
    PORT_FORWARD_PID=$!

    # Wait for port forward to be ready
    for i in {1..10}; do
        if check_port_forward; then
            log_success "Port forwarding established (PID: $PORT_FORWARD_PID)"
            return 0
        fi
        sleep 1
    done

    log_error "Port forwarding failed to establish"
    exit 1
}

# Make API request
make_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data_file="$3"

    local url="https://localhost:$LOCAL_PORT$endpoint"
    local curl_cmd="curl -k -s -X $method \"$url\" -H \"Authorization: Bearer $TOKEN\""

    if [[ -n "$data_file" ]]; then
        curl_cmd="$curl_cmd -H \"Content-Type: application/json\" -d @$data_file"
    fi

    eval "$curl_cmd"
}

# Send query to MCP service
send_query() {
    local query="$1"
    local temp_file="$TEMP_DIR/query-$(date +%s).json"

    log_info "Sending query to MCP service..."

    # Create request payload with proper JSON encoding
    jq -n --arg query "$query" '{"query": $query}' > "$temp_file"

    local response
    response=$(make_request "/v1/query" "POST" "$temp_file")

    if [[ $? -eq 0 ]]; then
        if [[ "$QUIET_MODE" == "true" ]]; then
            # In quiet mode, output only valid JSON
            echo "$response"
        else
            # In normal mode, pretty print JSON
            echo "$response" | jq . 2>/dev/null || echo "$response"
        fi
    else
        log_error "Failed to send query"
        return 1
    fi

    rm -f "$temp_file"
}

# Test service health
test_health() {
    log_info "Testing MCP service health..."

    local response
    response=$(make_request "/health" "GET")

    if [[ $? -eq 0 ]]; then
        log_success "Service is healthy"
        echo "$response"
    else
        log_error "Health check failed"
        return 1
    fi
}

# Create language test prompt
create_language_prompt() {
    local lang_code="$1"
    local prompt_type="${2:-precheck}"

    local constraint=""
    case "$lang_code" in
        "ko")
            constraint="- 🚨 필수 언어 요구사항: 반드시 한국어로만 응답해야 합니다. 모든 단어, 문장, 기술 용어, 설명을 한국어로 작성하세요."
            ;;
        "ja")
            constraint="- 🚨 重要な言語要件: 日本語で完全に応答する必要があります。すべての単語、文、技術用語、説明は日本語である必要があります。"
            ;;
        "es")
            constraint="- 🚨 REQUISITO CRÍTICO DE IDIOMA: Debes responder COMPLETAMENTE en español. Cada palabra, oración, término técnico y explicación debe estar en español."
            ;;
        "fr")
            constraint="- 🚨 EXIGENCE CRITIQUE DE LANGUE: Vous DEVEZ répondre ENTIÈREMENT en français. Chaque mot, phrase, terme technique et explication doit être en français."
            ;;
        "zh-CN")
            constraint="- 🚨 关键语言要求：您必须完全用简体中文回答。每个单词、句子、技术术语和解释都必须是中文。"
            ;;
        *)
            constraint="- LANGUAGE REQUIREMENT: Respond in English. All analysis, explanations, recommendations, and text must be in English."
            ;;
    esac

    cat << EOF
# OpenShift Cluster Upgrade ${prompt_type^} Analysis

<constraints>
$constraint

- Provide brief cluster analysis
- ONLY OUTPUT the Summary and TL;DR sections
</constraints>

<context>
Test prompt for $lang_code language compliance.
Scenario: OpenShift cluster version 4.21.3 with 3 available updates.
</context>

<output_format>
## Summary
[Brief analysis in target language]

## TL;DR
[Key points in target language]
</output_format>
EOF
}

# Test language prompt
test_language() {
    local lang_code="$1"
    local prompt_type="${2:-precheck}"

    log_info "Testing $lang_code language prompt ($prompt_type)..."

    local prompt
    prompt=$(create_language_prompt "$lang_code" "$prompt_type")

    # Escape quotes for JSON
    local escaped_prompt
    escaped_prompt=$(echo "$prompt" | sed 's/"/\\"/g' | tr '\n' ' ')

    local temp_file="$TEMP_DIR/test-$lang_code-$(date +%s).json"

    cat > "$temp_file" << EOF
{
  "query": "$escaped_prompt"
}
EOF

    log_success "Sending $lang_code test prompt..."

    local response
    response=$(make_request "/v1/query" "POST" "$temp_file")

    if [[ $? -eq 0 ]]; then
        echo
        echo "🌍 $lang_code Language Response:"
        echo "=================================="

        # Try to extract just the response text if JSON
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -r '.response // .rawResponse // .' 2>/dev/null || echo "$response"
            echo
            echo "📊 Metadata:"
            echo "$response" | jq '{conversation_id, input_tokens, output_tokens, referenced_documents: (.referenced_documents | length)}' 2>/dev/null || true
        else
            echo "$response"
        fi
        echo
    else
        log_error "Failed to test $lang_code language"
        return 1
    fi

    rm -f "$temp_file"
}

# Interactive mode
interactive_mode() {
    echo
    log_info "INTERACTIVE MCP CLIENT MODE"
    echo "=============================="
    echo "Commands:"
    echo "  test <lang> [type]  - Test language (ko, ja, es, fr, zh-CN, en)"
    echo "  query <text>        - Send custom query"
    echo "  health              - Check service health"
    echo "  quit                - Exit"
    echo

    while true; do
        echo -n "mcp> "
        read -r input

        if [[ -z "$input" ]]; then
            continue
        fi

        # Parse command
        set -- $input
        local command="$1"
        shift

        case "$command" in
            "test")
                local lang="${1:-ko}"
                local type="${2:-precheck}"
                test_language "$lang" "$type"
                ;;
            "query")
                local query="$*"
                if [[ -n "$query" ]]; then
                    send_query "$query"
                else
                    log_error "Please provide query text"
                fi
                ;;
            "health")
                test_health
                ;;
            "quit"|"exit")
                log_success "Goodbye!"
                exit 0
                ;;
            *)
                log_warning "Unknown command. Available: test, query, health, quit"
                ;;
        esac

        echo
    done
}

# Help function
show_help() {
    cat << EOF
MCP Client for OpenShift Lightspeed Service

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    test <lang> [type]     Test language prompt
                          Languages: ko, ja, es, fr, zh-CN, en
                          Types: precheck, progress, troubleshoot

    query "<text>"        Send custom query to MCP service

    health                Check MCP service health

    interactive           Start interactive mode (default if no command)

EXAMPLES:
    $0 test ko precheck          # Test Korean precheck prompt
    $0 query "Cluster status?"   # Send custom query
    $0 health                    # Check service health
    $0                           # Start interactive mode

OPTIONS:
    -h, --help            Show this help message
EOF
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            *)
                # Not a flag, break out of loop
                break
                ;;
        esac
    done

    # Initialize
    log_info "Initializing MCP Client..."

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo
    fi

    find_lightspeed_pod
    get_auth_token
    setup_port_forward

    # Test connection
    log_info "Testing connection..."
    if test_health >/dev/null 2>&1; then
        log_success "MCP Client ready!"
    else
        log_error "MCP service connection failed"
        exit 1
    fi

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo
    fi

    # Execute command or start interactive mode
    if [[ $# -eq 0 ]]; then
        interactive_mode
    else
        case "$1" in
            "test")
                test_language "$2" "$3"
                ;;
            "query")
                shift
                send_query "$*"
                ;;
            "health")
                test_health
                ;;
            "interactive")
                interactive_mode
                ;;
            *)
                log_error "Unknown command: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    fi
}

# Check dependencies
check_deps() {
    local missing_deps=()

    command -v oc >/dev/null 2>&1 || missing_deps+=("oc")
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing tools and try again."
        exit 1
    fi
}

# Entry point
check_deps
main "$@"