#!/bin/bash

# =======================================
#     SH to AppImage Builder Script
# =======================================

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the main logic
if [[ -f "${SCRIPT_DIR}/src/main.sh" ]]; then
    source "${SCRIPT_DIR}/src/main.sh"
else
    echo "Error: Core logic not found at ${SCRIPT_DIR}/src/main.sh"
    exit 1
fi