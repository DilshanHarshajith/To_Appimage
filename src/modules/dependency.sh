#!/bin/bash

# Dependency Module

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
