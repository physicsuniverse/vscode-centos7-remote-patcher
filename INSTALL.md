# Installation Guide

This guide provides detailed installation instructions for the VS Code Remote-SSH CentOS 7 Patcher.

## System Requirements

- **Operating System:** CentOS 7.9 (Core)
- **Architecture:** x86_64
- **Shell:** bash or zsh
- **Network:** Internet access for downloading packages
- **Permissions:** Regular user access (no root required)

## Installation Methods

### Method 1: Direct Download (Recommended)

```bash
# Download the patcher script
wget https://raw.githubusercontent.com/your-username/vscode-centos7-remote-patcher/main/vscode-centos7-patcher.sh

# Make it executable
chmod +x vscode-centos7-patcher.sh

# Run the auto-patcher
./vscode-centos7-patcher.sh --auto
```

### Method 2: Git Clone

```bash
# Clone the repository
git clone https://github.com/your-username/vscode-centos7-remote-patcher.git

# Navigate to the directory
cd vscode-centos7-remote-patcher

# Make the script executable
chmod +x vscode-centos7-patcher.sh

# Run the auto-patcher
./vscode-centos7-patcher.sh --auto
```

### Method 3: SCP from Local Machine

```bash
# From your local machine, copy the script to the server
scp vscode-centos7-patcher.sh your-server:~/

# SSH to your server
ssh your-server

# Make it executable and run
chmod +x ~/vscode-centos7-patcher.sh
./vscode-centos7-patcher.sh --auto
```

## Post-Installation

After running the patcher:

1. **Test VS Code Connection**: Try connecting to your CentOS server from VS Code Remote-SSH
2. **Check Logs**: Review `~/vscode-patcher.log` for any issues
3. **Verify Installation**: Run `./vscode-centos7-patcher.sh --check` to verify library versions

## Environment Setup

The patcher automatically sets up your environment, but you can manually verify:

```bash
# Check if the library path is set
echo $LD_LIBRARY_PATH

# It should include: /home/yourusername/local/usr/lib64
```

## Troubleshooting Installation

### Download Fails
```bash
# Check internet connectivity
ping -c 4 8.8.8.8

# Try alternative download method
curl -O https://raw.githubusercontent.com/your-username/vscode-centos7-remote-patcher/main/vscode-centos7-patcher.sh
```

### Permission Denied
```bash
# Ensure script is executable
ls -la vscode-centos7-patcher.sh
chmod +x vscode-centos7-patcher.sh
```

### Missing Dependencies
The script will automatically install required tools like `patchelf`, but ensure basic tools are available:

```bash
# Check for required tools
which wget || yum install -y wget
which rpm2cpio || yum install -y rpm
```

## Next Steps

After successful installation:

1. Connect to your server using VS Code Remote-SSH
2. Install your favorite VS Code extensions
3. Start coding on CentOS 7.9 with the latest VS Code features!

For detailed usage instructions, see the main [README.md](README.md) file.
