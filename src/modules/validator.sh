#!/bin/bash

# Validator Module

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

    # Validate Project Root
    if [[ -n "${PROJECT_ROOT:-}" ]]; then
        if [[ ! -d "$PROJECT_ROOT" ]]; then
             die "Project root not found: $PROJECT_ROOT"
        fi
        
        # Resolve absolute paths to check containment
        local abs_project
        abs_project=$(readlink -f "$PROJECT_ROOT")
        local abs_script
        abs_script=$(readlink -f "$INPUT_SCRIPT")
        
        if [[ "$abs_script" != "$abs_project"* ]]; then
            die "Input script ($INPUT_SCRIPT) must be inside project root ($PROJECT_ROOT)"
        fi
    fi
}
