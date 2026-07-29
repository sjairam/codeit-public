#!/bin/bash
# Save as cleanup_purgeable.sh

echo "Starting purgeable space cleanup..."

# Clear user caches
rm -rf ~/Library/Caches/* 2>/dev/null

# Clear system caches (requires sudo)
sudo rm -rf /Library/Caches/* 2>/dev/null

# Clear temporary files
rm -rf /tmp/* 2>/dev/null

# Clear Xcode derived data if present
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null

# Force APFS cleanup by filling and freeing space
sudo mkdir -p /private/tmp/cleanup
cd /private/tmp/cleanup
sudo dd if=/dev/zero of=./cleanupfile bs=100m count=10 2>/dev/null
sudo rm ./cleanupfile

echo "Cleanup complete. Run 'df -h' to check available space."