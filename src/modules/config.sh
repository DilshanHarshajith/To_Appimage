#!/bin/bash

# Config Module

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION - Convert shell scripts to AppImage format

USAGE:
    $SCRIPT_NAME [OPTIONS] <script.sh> [AppName]

ARGUMENTS:
    <script.sh>    Path to the shell script to convert
    [AppName]      Name for the AppImage (default: script basename)

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -f, --force             Force rebuild (remove existing AppDir)
    -a, --arch ARCH         Target architecture (default: $DEFAULT_ARCH)
    -c, --categories CATS   Desktop categories (default: $CATEGORIES)
    -i, --icon PATH         Path to custom icon file
    -s, --icon-size SIZE    Icon size in pixels (default: $ICON_SIZE)
    -t, --no-terminal       Don't run in terminal
    -p, --project DIR       Project root directory (preserves structure)
    --assets DIR            Directory of assets to copy to /usr/bin
    --tempdir               App will extract to a writable temp dir at runtime
    --cleanup-success       Clean up build directory on success (default: $CLEANUP_ON_SUCCESS)
    --no-cleanup-success    Don't clean up build directory on success
    --cleanup-failure       Clean up build directory on failure (default: $CLEANUP_ON_FAILURE)
    --no-cleanup-failure    Don't clean up build directory on failure
    --version               Show version information

EXAMPLES:
    $SCRIPT_NAME myscript.sh
    $SCRIPT_NAME --verbose --force myscript.sh MyApp
    $SCRIPT_NAME --icon myicon.png --categories "Development;IDE;" script.sh

CONFIGURATION:
    Create $CONFIG_FILE to set default options.
    Example:
        CLEANUP_ON_SUCCESS=false
        VERBOSE=true
        CATEGORIES="Development;IDE;"
EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_REBUILD=true
                shift
                ;;
            -a|--arch)
                ARCH="$2"
                shift 2
                ;;
            -c|--categories)
                CATEGORIES="$2"
                shift 2
                ;;
            -i|--icon)
                CUSTOM_ICON="$2"
                shift 2
                ;;
            -s|--icon-size)
                ICON_SIZE="$2"
                shift 2
                ;;
            -t|--no-terminal)
                TERMINAL_APP=false
                shift
                ;;
            --cleanup-success)
                CLEANUP_ON_SUCCESS=true
                shift
                ;;
            --no-cleanup-success)
                CLEANUP_ON_SUCCESS=false
                shift
                ;;
            --cleanup-failure)
                CLEANUP_ON_FAILURE=true
                shift
                ;;
            --no-cleanup-failure)
                CLEANUP_ON_FAILURE=false
                shift
                ;;
            --assets)
                ASSETS_DIR="$2"
                shift 2
                ;;
            --tempdir)
                TEMP_MODE=true
                shift
                ;;
            -p|--project)
                PROJECT_ROOT="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                break
                ;;
        esac
    done
    
    # If no arguments provided, start interactive mode
    if [[ $# -lt 1 ]]; then
        interactive_mode
    else
        INPUT_SCRIPT="$1"
        APP_NAME="${2:-$(basename "$1" .sh)}"
        ARCH="${ARCH:-$DEFAULT_ARCH}"
    fi
}

interactive_mode() {
    log "INFO" "Entering interactive mode..."
    echo -e "${BLUE}=== To_Appimage Interactive Mode ===${NC}"
    echo
    
    # 1. Input Script
    while true; do
        read -r -p "Enter path to shell script: " input_script
        # Expand user path (~) if necessary or use as is
        input_script="${input_script/#\~/$HOME}"
        
        if [[ -f "$input_script" ]]; then
            INPUT_SCRIPT="$input_script"
            break
        else
            echo -e "${RED}File not found: $input_script${NC}"
        fi
    done
    
    # 2. App Name
    local default_name
    default_name="$(basename "$INPUT_SCRIPT" .sh)"
    read -r -p "Enter AppImage name [$default_name]: " app_name
    APP_NAME="${app_name:-$default_name}"
    
    # 3. Icon
    read -r -p "Enter path to icon (optional): " custom_icon
    if [[ -n "$custom_icon" ]]; then
        custom_icon="${custom_icon/#\~/$HOME}"
        if [[ -f "$custom_icon" ]]; then
            CUSTOM_ICON="$custom_icon"
        else
            echo -e "${YELLOW}Icon file not found, using default.${NC}"
        fi
    fi
    
    # 4. Categories
    read -r -p "Enter categories [$CATEGORIES]: " categories
    CATEGORIES="${categories:-$CATEGORIES}"
    
    # 5. Architecture
    read -r -p "Enter architecture [$DEFAULT_ARCH]: " arch
    ARCH="${arch:-$DEFAULT_ARCH}"
    
    echo
    log "INFO" "Interactive configuration complete."
}
