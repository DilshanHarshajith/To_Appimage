# SH to AppImage Builder

A tool for converting shell scripts into portable AppImage packages that can run on any Linux distribution.

## Features

- 🚀 **Simple Usage**: Convert any shell script to AppImage with one command
- 🔧 **Highly Configurable**: Extensive command-line options and configuration file support
- 📦 **Self-Contained**: Automatically downloads required tools
- 🎨 **Custom Icons**: Support for custom icons with automatic resizing
- 📝 **Comprehensive Logging**: Detailed logging with colored output
- 🛡️ **Robust Error Handling**: Proper validation and error recovery
- 🧹 **Clean Builds**: Configurable cleanup behavior
- 🏗️ **Architecture Support**: Multi-architecture AppImage generation

## Quick Start

```bash
# Basic usage - convert a script to AppImage
./To_Appimage.sh myscript.sh

# With custom app name
./To_Appimage.sh myscript.sh MyAwesomeApp

# Advanced usage with options
./To_Appimage.sh --verbose --force --icon myicon.png myscript.sh
```

## Installation

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/DilshanHarshajith/To_Appimage/refs/heads/main/To_Appimage.sh
   chmod +x To_Appimage.sh
   ```

2. **Required Dependencies**:
   - `bash` (4.0+)
   - `wget`
   - `chmod`, `mkdir`, `cp`, `rm`, `cat` (standard coreutils)

3. **Optional Dependencies**:
   - `ImageMagick` (for custom icon generation and resizing)

## Usage

### Basic Syntax

```bash
./To_Appimage.sh [OPTIONS] <script.sh> [AppName]
```

### Arguments

- `<script.sh>`: Path to the shell script to convert (required)
- `[AppName]`: Name for the AppImage (optional, defaults to script basename)

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-h, --help` | Show help message | |
| `-v, --verbose` | Enable verbose output | false |
| `-f, --force` | Force rebuild (remove existing files) | false |
| `-a, --arch ARCH` | Target architecture | x86_64 |
| `-c, --categories CATS` | Desktop categories | "Utility;Network;" |
| `-i, --icon PATH` | Path to custom icon file | Generated |
| `-s, --icon-size SIZE` | Icon size in pixels (16-512) | 128 |
| `-t, --no-terminal` | Don't run in terminal | false |
| `--cleanup-success` | Clean up build directory on success | true |
| `--no-cleanup-success` | Don't clean up on success | |
| `--cleanup-failure` | Clean up build directory on failure | false |
| `--no-cleanup-failure` | Don't clean up on failure | |
| `--version` | Show version information | |

### Examples

#### Basic Usage
```bash
# Convert a simple script
./To_Appimage.sh backup.sh

# Convert with custom name
./To_Appimage.sh backup.sh BackupTool
```

#### Advanced Usage
```bash
# Development tool with custom icon
./To_Appimage.sh --verbose \
  --icon myapp.png \
  --categories "Development;IDE;" \
  --no-terminal \
  deploy.sh DevTool

# Force rebuild with cleanup
./To_Appimage.sh --force \
  --cleanup-success \
  --arch x86_64 \
  myscript.sh
```

#### Network Tool
```bash
# Network utility that runs in terminal
./To_Appimage.sh --categories "Network;System;" \
  --icon network.png \
  --icon-size 64 \
  netmon.sh NetworkMonitor
```

## Configuration File

Create a `.appimage-builder.conf` file in the same directory as the script for default settings:

```bash
# Example configuration file
CLEANUP_ON_SUCCESS=false
VERBOSE=true
CATEGORIES="Development;IDE;"
ICON_SIZE=64
TERMINAL_APP=false
FORCE_REBUILD=false
```

### Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `CLEANUP_ON_SUCCESS` | Clean build directory on success | true |
| `CLEANUP_ON_FAILURE` | Clean build directory on failure | false |
| `FORCE_REBUILD` | Always force rebuild | false |
| `VERBOSE` | Enable verbose logging | false |
| `TERMINAL_APP` | Run application in terminal | true |
| `ICON_SIZE` | Default icon size | 128 |
| `CATEGORIES` | Desktop categories | "Utility;Network;" |

## File Structure

The script creates the following structure:

```
project-directory/
├── To_Appimage.sh          # Main script
├── .appimage-builder.conf       # Optional configuration
├── appimage-builder.log         # Build log
├── appimagetool-x86_64.AppImage # Downloaded tool
├── MyApp-AppDir/                # Build directory
│   ├── AppRun                   # AppImage entry point
│   ├── MyApp.desktop            # Desktop file
│   └── usr/
│       ├── bin/
│       │   └── MyApp            # Your script
│       └── share/
│           └── icons/
│               └── hicolor/
│                   └── 128x128/
│                       └── apps/
│                           └── MyApp.png
└── MyApp-x86_64.AppImage        # Final AppImage
```

## Desktop Integration

The generated AppImage includes:

- **Desktop Entry**: Proper `.desktop` file with categories and metadata
- **Icon**: Custom or auto-generated icon in multiple sizes
- **MIME Types**: Configurable application categories
- **Terminal Support**: Optional terminal execution

### Desktop Categories

Common categories for different types of applications:

- **Development**: `Development;IDE;`
- **Network Tools**: `Network;System;`
- **Utilities**: `Utility;System;`
- **System Tools**: `System;Monitor;`
- **Games**: `Game;`
- **Graphics**: `Graphics;Photography;`
- **Office**: `Office;`

## Icon Support

### Custom Icons
```bash
# PNG, JPG, SVG supported
./To_Appimage.sh --icon myicon.png myscript.sh

# Auto-resize to specified size
./To_Appimage.sh --icon large.png --icon-size 64 myscript.sh
```

### Auto-Generated Icons
If no custom icon is provided, the script generates a default icon with:
- App name initials (first 3 characters)
- Professional blue background
- White text
- Configurable size

## Logging and Debugging

### Log File
All operations are logged to `appimage-builder.log`:
```bash
# View recent logs
tail -f appimage-builder.log

# View error logs only
grep ERROR appimage-builder.log
```

### Verbose Mode
Enable detailed output:
```bash
./To_Appimage.sh --verbose myscript.sh
```

### Debug Information
Verbose mode shows:
- Configuration values
- File operations
- Build steps
- Dependency checks

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x To_Appimage.sh
   chmod +x your-script.sh
   ```

2. **Missing Dependencies**
   ```bash
   # Ubuntu/Debian
   sudo apt install wget imagemagick
   
   # RHEL/CentOS
   sudo yum install wget ImageMagick
   ```

3. **AppImage Tool Download Fails**
   ```bash
   # Manual download
   wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   ```

4. **Build Directory Exists**
   ```bash
   # Force rebuild
   ./To_Appimage.sh --force myscript.sh
   ```

### Error Messages

| Error | Solution |
|-------|----------|
| "Input script not found" | Check file path and permissions |
| "Build directory already exists" | Use `--force` option |
| "Invalid app name" | Use only alphanumeric, underscore, hyphen |
| "Failed to download AppImage tool" | Check internet connection |
| "Missing required dependencies" | Install missing packages |

## Advanced Usage

### Custom AppRun Script
The generated AppRun script can be customized by modifying the `create_apprun()` function in the main script.

### Environment Variables
Set custom environment variables in your script:
```bash
#!/bin/bash
export MY_APP_CONFIG="/path/to/config"
export MY_APP_DEBUG=1
# Your script logic here
```

### Multi-Architecture Support
```bash
# Build for different architectures
./To_Appimage.sh --arch x86_64 myscript.sh
./To_Appimage.sh --arch aarch64 myscript.sh
```

## Best Practices

### Script Preparation
1. **Make scripts executable**: `chmod +x myscript.sh`
2. **Include proper shebang**: `#!/bin/bash`
3. **Handle dependencies**: Include all required files
4. **Test thoroughly**: Test script independently first

### AppImage Optimization
1. **Keep scripts small**: Minimize dependencies
2. **Use relative paths**: Avoid absolute paths when possible
3. **Include help text**: Add `--help` option to your script
4. **Handle signals**: Implement proper cleanup in scripts

### Distribution
1. **Test on multiple distros**: Verify compatibility
2. **Document requirements**: List any system dependencies
3. **Provide checksums**: Include SHA256 hashes
4. **Version your AppImages**: Use semantic versioning

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

- **Issues**: Report bugs and request features on GitHub
---
