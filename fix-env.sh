#!/bin/bash

# Quick fix for the LD_LIBRARY_PATH issue
echo "Fixing LD_LIBRARY_PATH issue..."

# Remove the problematic line from .bashrc
if grep -q "LD_LIBRARY_PATH.*local" ~/.bashrc; then
    echo "Removing problematic LD_LIBRARY_PATH from .bashrc..."
    sed -i '/LD_LIBRARY_PATH.*local/d' ~/.bashrc
    echo "✓ Removed from .bashrc"
fi

# Unset the current environment variable
if [[ "$LD_LIBRARY_PATH" == *"local"* ]]; then
    echo "Unsetting LD_LIBRARY_PATH for current session..."
    unset LD_LIBRARY_PATH
    echo "✓ Unset for current session"
fi

echo "✓ Fix complete! You can now run the patcher script safely."
echo "Note: The script now uses patchelf only, no global LD_LIBRARY_PATH needed."
