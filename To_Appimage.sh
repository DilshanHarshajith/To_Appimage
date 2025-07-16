#!/bin/bash

# =======================================
#     SH to AppImage Builder Script
# =======================================

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="1.0.0"
readonly DEFAULT_ARCH="x86_64"
readonly APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${DEFAULT_ARCH}.AppImage"
readonly LOG_FILE="${SCRIPT_DIR}/appimage-builder.log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration file support
readonly CONFIG_FILE="${SCRIPT_DIR}/.appimage-builder.conf"

# Default configuration
CLEANUP_ON_SUCCESS=true
CLEANUP_ON_FAILURE=false
FORCE_REBUILD=false
VERBOSE=false
TERMINAL_APP=true
ICON_SIZE=128
CATEGORIES="Utility;Network;"

# =======================================
#           Utility Functions
# =======================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
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
            [[ "$VERBOSE" == "true" ]] && echo -e "[DEBUG] $message"
            ;;
    esac
}

die() {
    log "ERROR" "$*"
    exit 1
}

check_dependencies() {
    local deps=("wget" "chmod" "mkdir" "cp" "rm" "cat" "basename" "dirname")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required dependencies: ${missing[*]}"
    fi
    
    # Check for ImageMagick (optional)
    if ! command -v convert &> /dev/null; then
        log "WARN" "ImageMagick not found. Default icon will be a placeholder file."
    fi
}

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
    
    # Validate required arguments
    if [[ $# -lt 1 ]]; then
        log "ERROR" "Missing required argument: script file"
        echo
        show_help
        exit 1
    fi
    
    INPUT_SCRIPT="$1"
    APP_NAME="${2:-$(basename "$1" .sh)}"
    ARCH="${ARCH:-$DEFAULT_ARCH}"
}

validate_inputs() {
    # Check input script exists and is readable
    if [[ ! -f "$INPUT_SCRIPT" ]]; then
        die "Input script not found: $INPUT_SCRIPT"
    fi
    
    if [[ ! -r "$INPUT_SCRIPT" ]]; then
        die "Input script not readable: $INPUT_SCRIPT"
    fi
    
    # Check if it's a shell script
    if [[ ! -x "$INPUT_SCRIPT" ]] && [[ "$(head -n1 "$INPUT_SCRIPT")" != \#!*bash* ]] && [[ "$(head -n1 "$INPUT_SCRIPT")" != \#!*/sh* ]]; then
        log "WARN" "Input file may not be a shell script"
    fi
    
    # Validate app name
    if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        die "Invalid app name: $APP_NAME (only alphanumeric, underscore, and hyphen allowed)"
    fi
    
    # Validate custom icon if provided
    if [[ -n "${CUSTOM_ICON:-}" ]] && [[ ! -f "$CUSTOM_ICON" ]]; then
        die "Custom icon file not found: $CUSTOM_ICON"
    fi
    
    # Validate icon size
    if [[ ! "$ICON_SIZE" =~ ^[0-9]+$ ]] || [[ "$ICON_SIZE" -lt 16 ]] || [[ "$ICON_SIZE" -gt 512 ]]; then
        die "Invalid icon size: $ICON_SIZE (must be between 16 and 512)"
    fi
}

setup_build_environment() {
    BUILD_DIR="${SCRIPT_DIR}/${APP_NAME}-AppDir"
    APPIMAGE_TOOL="${SCRIPT_DIR}/appimagetool-${ARCH}.AppImage"
    OUTPUT_FILE="${SCRIPT_DIR}/${APP_NAME}-${ARCH}.AppImage"
    
    # Handle existing build directory
    if [[ -d "$BUILD_DIR" ]]; then
        if [[ "$FORCE_REBUILD" == "true" ]]; then
            log "INFO" "Removing existing build directory: $BUILD_DIR"
            rm -rf "$BUILD_DIR"
        else
            die "Build directory already exists: $BUILD_DIR (use --force to overwrite)"
        fi
    fi
    
    # Handle existing AppImage
    if [[ -f "$OUTPUT_FILE" ]]; then
        if [[ "$FORCE_REBUILD" == "true" ]]; then
            log "INFO" "Removing existing AppImage: $OUTPUT_FILE"
            rm -f "$OUTPUT_FILE"
        else
            die "AppImage already exists: $OUTPUT_FILE (use --force to overwrite)"
        fi
    fi
}

download_appimagetool() {
    if [[ ! -f "$APPIMAGE_TOOL" ]]; then
        log "INFO" "Downloading AppImage tool for $ARCH..."
        
        local tool_url="${APPIMAGE_TOOL_URL//$DEFAULT_ARCH/$ARCH}"
        
        if ! wget -q --show-progress "$tool_url" -O "$APPIMAGE_TOOL"; then
            die "Failed to download AppImage tool from $tool_url"
        fi
        
        chmod +x "$APPIMAGE_TOOL"
        log "SUCCESS" "AppImage tool downloaded successfully"
    else
        log "DEBUG" "AppImage tool already exists: $APPIMAGE_TOOL"
    fi
}

create_appdir_structure() {
    log "INFO" "Creating AppDir structure..."
    
    # Create directory structure
    mkdir -p "$BUILD_DIR/usr/bin"
    mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/${ICON_SIZE}x${ICON_SIZE}/apps"
    mkdir -p "$BUILD_DIR/usr/share/applications"
    
    # Copy the input script
    cp "$INPUT_SCRIPT" "$BUILD_DIR/usr/bin/$APP_NAME"
    chmod +x "$BUILD_DIR/usr/bin/$APP_NAME"
    
    log "SUCCESS" "Script copied to $BUILD_DIR/usr/bin/$APP_NAME"
}

create_icon() {
    local icon_path="$BUILD_DIR/usr/share/icons/hicolor/${ICON_SIZE}x${ICON_SIZE}/apps/${APP_NAME}.png"
    
    if [[ -n "${CUSTOM_ICON:-}" ]]; then
        log "INFO" "Using custom icon: $CUSTOM_ICON"
        if command -v convert &> /dev/null; then
            convert "$CUSTOM_ICON" -resize "${ICON_SIZE}x${ICON_SIZE}" "$icon_path"
        else
            cp "$CUSTOM_ICON" "$icon_path"
        fi
    else
        log "INFO" "Creating default icon..."
        if command -v convert &> /dev/null; then
            convert -size "${ICON_SIZE}x${ICON_SIZE}" \
                    -background "#4a90e2" \
                    -fill white \
                    -gravity center \
                    -pointsize $((ICON_SIZE / 6)) \
                    label:"${APP_NAME:0:3}" \
                    "$icon_path"
        else
            # Create placeholder file
            touch "$icon_path"
            log "WARN" "Created placeholder icon (ImageMagick not available)"
        fi
    fi
    
    log "SUCCESS" "Icon created: $icon_path"
}

create_desktop_file() {
    local desktop_file="$BUILD_DIR/$APP_NAME.desktop"
    
    log "INFO" "Creating desktop file..."
    
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Type=Application
Categories=$CATEGORIES
Terminal=$TERMINAL_APP
Version=1.0
Comment=Shell script packaged as AppImage
Keywords=shell;script;utility;
StartupNotify=true
EOF
    
    log "SUCCESS" "Desktop file created: $desktop_file"
}

create_apprun() {
    local apprun_file="$BUILD_DIR/AppRun"
    
    log "INFO" "Creating AppRun file..."
    
    cat > "$apprun_file" <<'EOF'
#!/bin/bash

# Get the directory where this AppRun script is located
APPDIR="$(dirname "$(readlink -f "$0")")"

# Set up environment
export PATH="$APPDIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$APPDIR/usr/lib:$LD_LIBRARY_PATH"

# Execute the wrapped script
exec "$APPDIR/usr/bin/$(basename "$APPDIR" | sed 's/-AppDir$//')" "$@"
EOF
    
    # Make it executable
    chmod +x "$apprun_file"
    
    log "SUCCESS" "AppRun file created: $apprun_file"
}

build_appimage() {
    log "INFO" "Building AppImage..."
    
    # Make sure the AppImage tool is executable
    chmod +x "$APPIMAGE_TOOL"
    
    # Build the AppImage
    if ! "$APPIMAGE_TOOL" "$BUILD_DIR" &>> "$LOG_FILE"; then
        die "Failed to build AppImage. Check $LOG_FILE for details."
    fi
    
    # Find the created AppImage (appimagetool might change the name)
    local created_appimage
    created_appimage=$(find "$SCRIPT_DIR" -name "${APP_NAME}*.AppImage" -newer "$BUILD_DIR" | head -n1)
    
    if [[ -z "$created_appimage" ]]; then
        die "AppImage was not created successfully"
    fi
    
    # Rename to expected filename if different
    if [[ "$created_appimage" != "$OUTPUT_FILE" ]]; then
        mv "$created_appimage" "$OUTPUT_FILE"
    fi
    
    log "SUCCESS" "AppImage created: $OUTPUT_FILE"
}

cleanup() {
    local success="$1"
    
    if [[ "$success" == "true" && "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        log "INFO" "Cleaning up build directory..."
        rm -rf "$BUILD_DIR"
    elif [[ "$success" == "false" && "$CLEANUP_ON_FAILURE" == "true" ]]; then
        log "INFO" "Cleaning up build directory after failure..."
        rm -rf "$BUILD_DIR"
    fi
}

# =======================================
#              Main Function
# =======================================

main() {
    # Initialize logging
    echo "[$SCRIPT_NAME] Starting at $(date)" > "$LOG_FILE"
    
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
    log "INFO" "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Make the AppImage executable
    chmod +x "$OUTPUT_FILE"
    
    echo
    log "SUCCESS" "✓ AppImage ready: $OUTPUT_FILE"
}

# Run main function with all arguments
main "$@"