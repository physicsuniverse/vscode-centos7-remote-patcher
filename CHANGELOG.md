# Changelog

All notable changes to the VS Code Remote-SSH CentOS 7 Patcher will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-29

### Added
- Initial release of VS Code Remote-SSH CentOS 7 Patcher
- Automatic download and installation of compatible glibc 2.28 and libstdc++ 8.5.0
- Binary patching using patchelf for VS Code Server compatibility
- Automatic monitoring for new VS Code Server installations
- Support for multiple operation modes: --auto, --setup, --patch, --monitor, --check, --clean
- Comprehensive logging system
- Environment variable setup for library paths
- User-space installation (no root required)
- Support for CentOS 7.9 x86_64

### Features
- **Auto Mode**: One-command setup and patching
- **Setup Mode**: Download and prepare libraries without patching
- **Patch Mode**: Patch existing VS Code Server installations
- **Monitor Mode**: Background monitoring for new installations
- **Check Mode**: Verify current library versions and installation status
- **Clean Mode**: Remove installed components
- **Fix Environment**: Helper script for environment issues

### Technical Details
- Uses AlmaLinux 8 compatible libraries
- Implements RPATH modification for binary compatibility
- Preserves original VS Code Server functionality
- Thread-safe operations with proper locking
- Detailed error handling and recovery

### Documentation
- Comprehensive README with quick start guide
- Detailed installation instructions
- Troubleshooting guide
- Technical implementation details
- MIT License

### Compatibility
- CentOS 7.9 (Core) x86_64
- VS Code versions 1.86+
- bash and zsh shells
- Remote-SSH extension latest versions
