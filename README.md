# To_Appimage.sh

A powerful, modular utility to convert your shell scripts into portable AppImages.

## Features

- **Convert Single Scripts**: Instantly wrap a shell script into an AppImage.
- **Project Support**: Package complex applications with sub-modules using `--project`.
- **Asset Bundling**: Include extra files (images, configs) with `--assets`.
- **Interactive Mode**: User-friendly wizard if no arguments are provided.
- **Customizable**: Set custom icons, categories, and architectures.
- **Robust**: Automatic dependency checking and build environment management.

## Installation

Simply clone the repository and make the script executable:

```bash
git clone https://github.com/yourusername/To_Appimage.git
cd To_Appimage
chmod +x To_Appimage.sh
```

## Usage

### 1. Interactive Mode

Run without arguments to start the interactive wizard:

```bash
./To_Appimage.sh
```

### 2. Single Script

Convert a simple standalone script:

```bash
./To_Appimage.sh myscript.sh
```

### 3. Modular Project (Recommended)

For scripts that depend on other files (e.g., `source ./lib/utils.sh`), use the `--project` flag to preserve the directory structure:

```bash
./To_Appimage.sh --project ./my_project ./my_project/main.sh
```

_Note: The script path must be inside the project directory._

### 4. Bundling Assets

To include extra assets (like images or default configs) into `/usr/bin` of the AppImage:

```bash
./To_Appimage.sh --assets ./my_assets myscript.sh
```

### 5. Advanced Options

```bash
./To_Appimage.sh [OPTIONS] <script.sh> [AppName]

OPTIONS:
    -h, --help              Show help message
    -v, --verbose           Enable verbose output
    -f, --force             Force rebuild (remove existing AppDir)
    -a, --arch ARCH         Target architecture (default: x86_64)
    -c, --categories CATS   Desktop categories (default: Utility;Network;)
    -i, --icon PATH         Path to custom icon file
    -s, --icon-size SIZE    Icon size in pixels (default: 128)
    -p, --project DIR       Project root directory (preserves structure)
    --assets DIR            Directory of assets to copy to /usr/bin
    --tempdir               Extract app to writable temp dir at runtime (for apps that need write access)
    --cleanup-success       Clean up build directory on success (default: true)
```

## Structure

The tool is modularized for easy maintenance:

```
To_Appimage/
├── To_Appimage.sh      # Entry point
└── src/
    ├── main.sh         # Core logic
    └── modules/        # Functional modules
        ├── builder.sh
        ├── config.sh
        ├── dependency.sh
        ├── logger.sh
        └── validator.sh
```

## Requirements

- `wget`
- `glibc` (standard on most Linux distros)
- `ImageMagick` (optional, for icon processing)

## License

MIT
