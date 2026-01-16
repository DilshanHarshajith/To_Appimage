#!/bin/bash

# Main Script Logic

# --- Configuration ---
readonly VERSION="1.0.0"
readonly DEFAULT_ARCH="x86_64"
readonly APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${DEFAULT_ARCH}.AppImage"
readonly LOG_FILE="${SCRIPT_DIR}/appimage-builder.log"
readonly CONFIG_FILE="${SCRIPT_DIR}/.appimage-builder.conf"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default configuration
CLEANUP_ON_SUCCESS=true
CLEANUP_ON_FAILURE=false
FORCE_REBUILD=false
VERBOSE=false
TERMINAL_APP=true
ICON_SIZE=128
CATEGORIES="Utility;Network;"
TEMP_MODE=false

# --- Module Loading ---
source "${SCRIPT_DIR}/src/modules/logger.sh"
source "${SCRIPT_DIR}/src/modules/config.sh"
source "${SCRIPT_DIR}/src/modules/dependency.sh"
source "${SCRIPT_DIR}/src/modules/validator.sh"
source "${SCRIPT_DIR}/src/modules/builder.sh"

# --- Main Execution ---
main() {
    # Initialize logging
    # LOG_FILE is defined above, but we need to ensure it's writable or fallback
    echo "[$SCRIPT_NAME] Starting at $(date)" >> "$LOG_FILE" 2>/dev/null || true
    
    # Load configuration
    load_config
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show configuration in verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        log "DEBUG" "Configuration:"
        log "DEBUG" "  Input script: $INPUT_SCRIPT"
        log "DEBUG" "  App name: $APP_NAME"
        log "DEBUG" "  Architecture: $ARCH"
        log "DEBUG" "  Categories: $CATEGORIES"
        log "DEBUG" "  Icon size: $ICON_SIZE"
        log "DEBUG" "  Terminal app: $TERMINAL_APP"
        log "DEBUG" "  Cleanup on success: $CLEANUP_ON_SUCCESS"
        log "DEBUG" "  Cleanup on failure: $CLEANUP_ON_FAILURE"
    fi
    
    # Setup trap for cleanup on failure
    trap 'cleanup false' ERR
    
    # Main execution steps
    log "INFO" "Starting AppImage build process..."
    
    check_dependencies
    validate_inputs
    setup_build_environment
    download_appimagetool
    create_appdir_structure
    create_icon
    create_desktop_file
    create_apprun
    build_appimage
    
    # Success cleanup
    cleanup true
    
    log "SUCCESS" "AppImage build completed successfully!"
    log "INFO" "Output file: $OUTPUT_FILE"
    if command -v du &> /dev/null; then
        log "INFO" "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    fi
    
    # Make the AppImage executable
    chmod +x "$OUTPUT_FILE"
    
    echo
    log "SUCCESS" "✓ AppImage ready: $OUTPUT_FILE"
}

main "$@"
