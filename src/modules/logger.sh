#!/bin/bash

# Logger Module

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure LOG_FILE is defined, otherwise dump to /dev/null or stderr
    local log_target="${LOG_FILE:-/dev/null}"

    if [[ -w "$(dirname "$log_target")" ]]; then
         echo "[$timestamp] [$level] $message" >> "$log_target"
    fi
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "DEBUG")
            if [[ "${VERBOSE:-false}" == "true" ]]; then
                echo -e "[DEBUG] $message"
            fi
            ;;
    esac
}

die() {
    log "ERROR" "$*"
    exit 1
}
