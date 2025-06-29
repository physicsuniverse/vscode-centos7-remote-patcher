# VS Code Remote-SSH CentOS 7 Patcher

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![CentOS](https://img.shields.io/badge/CentOS-7.9-red.svg)](https://www.centos.org/)

A comprehensive solution for using the latest VS Code Remote-SSH extension with CentOS 7.9 servers by automatically patching library dependencies.

## 🎯 Problem Overview

Microsoft dropped official support for CentOS 7 in VS Code version 1.86 (January 2024) due to outdated system libraries. CentOS 7.9 ships with:

- **glibc 2.17** (VS Code requires 2.28+)
- **libstdc++ 3.4.19** (VS Code requires 3.4.21+)

This causes VS Code Remote-SSH to fail with library version errors when trying to use recent VS Code versions (1.86+).

## 🚀 Solution

This project provides an automated solution that:

1. **Downloads newer compatible libraries** (glibc 2.28+ and libstdc++ 3.4.25+) from AlmaLinux 8 repositories
2. **Installs libraries in user space** without modifying the system
3. **Automatically patches VS Code Server binaries** to use the newer libraries
4. **Monitors for new VS Code installations** and patches them automatically
5. **Preserves system integrity** - no root access required

## 📋 Prerequisites

- SSH access to CentOS 7.9 server
- Local machine with latest VS Code and Remote-SSH extension
- Basic Linux command line knowledge
- Internet access on the CentOS server

## 🛠️ Quick Start

### 1. Download the Patcher

**Option A: Copy to your server**
```bash
scp vscode-centos7-patcher.sh your-server:~/
ssh your-server "chmod +x ~/vscode-centos7-patcher.sh"
```

**Option B: Download directly on server**
```bash
wget https://raw.githubusercontent.com/your-username/vscode-centos7-remote-patcher/main/vscode-centos7-patcher.sh
chmod +x vscode-centos7-patcher.sh
```

### 2. Run the Auto-Patcher

```bash
./vscode-centos7-patcher.sh --auto
```

This single command will:
- ✅ Download and extract newer glibc and libstdc++ libraries
- ✅ Install patchelf tool
- ✅ Set up environment variables
- ✅ Patch any existing VS Code server installations
- ✅ Set up monitoring for future installations

### 3. Connect with VS Code

Open VS Code on your local machine and connect to your CentOS 7.9 server using Remote-SSH. The connection should now work seamlessly with the latest VS Code versions!

## 📖 Usage Options

### Complete Automation (Recommended)
```bash
./vscode-centos7-patcher.sh --auto
```
Performs all setup and patching operations automatically.

### Individual Operations

**Setup libraries only (no patching yet):**
```bash
./vscode-centos7-patcher.sh --setup
```

**Patch existing VS Code servers:**
```bash
./vscode-centos7-patcher.sh --patch
```

**Monitor for new VS Code installations:**
```bash
./vscode-centos7-patcher.sh --monitor
```

**Check current system libraries:**
```bash
./vscode-centos7-patcher.sh --check
```

**Clean up installation:**
```bash
./vscode-centos7-patcher.sh --clean
```

**Show help:**
```bash
./vscode-centos7-patcher.sh --help
```

## 🔧 How It Works

### 1. Library Installation
- Downloads compatible glibc 2.28 and libstdc++ 8.5.0 from AlmaLinux 8 repositories
- Extracts RPM packages to `~/local/usr/lib64/` without system modification
- Sets up `LD_LIBRARY_PATH` to include the new libraries

### 2. Binary Patching
- Uses `patchelf` to modify VS Code Server binaries
- Updates dynamic linker and RPATH to use newer libraries
- Preserves original functionality while enabling modern library support

### 3. Automatic Monitoring
- Monitors `~/.vscode-server/` for new installations
- Automatically patches new VS Code Server versions as they're installed
- Runs as a background service when enabled

## 🗂️ File Structure

```
~/
├── local/
│   ├── usr/lib64/          # Newer libraries (glibc, libstdc++)
│   └── bin/patchelf        # Binary patching tool
├── bin/
│   └── patchelf           # Symlink for easy access
├── .vscode-server/        # VS Code Server installations (patched)
└── vscode-patcher.log     # Installation and patching logs
```

## ✅ Compatibility

- **Tested on:** CentOS 7.9 (Core)
- **VS Code versions:** 1.86+ (latest versions)
- **Architecture:** x86_64
- **Shell:** bash, zsh compatible

## 🐛 Troubleshooting

### Connection Still Fails
1. Check the log file: `cat ~/vscode-patcher.log`
2. Verify library installation: `./vscode-centos7-patcher.sh --check`
3. Re-run the patcher: `./vscode-centos7-patcher.sh --patch`

### Permission Issues
- Ensure the script is executable: `chmod +x vscode-centos7-patcher.sh`
- No root access required - all operations are in user space

### Network Issues
- Ensure your server has internet access to download packages
- Check firewall settings if downloads fail

## 🧹 Environment Fix

If you encounter environment issues, use the included fix script:

```bash
./fix-env.sh
```

This script helps resolve common environment configuration problems.

## 📝 Logging

All operations are logged to `~/vscode-patcher.log` for debugging and monitoring purposes.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Microsoft VS Code team for the excellent Remote-SSH extension
- AlmaLinux project for providing compatible library packages
- NixOS team for the patchelf utility

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review the log file: `~/vscode-patcher.log`
3. Open an issue on GitHub with:
   - Your CentOS version (`cat /etc/centos-release`)
   - VS Code version
   - Error messages from the log file

---

**Made with ❤️ for the CentOS 7 community who aren't ready to upgrade yet!**
