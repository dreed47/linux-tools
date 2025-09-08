#!/bin/bash

# Emergency Proxmox Cleanup Script
# Use this when disk is 99% full

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}EMERGENCY DISK CLEANUP - DISK IS 99% FULL${NC}"
echo

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Must be run as root!${NC}"
    exit 1
fi

# Show current status
echo "Current disk usage:"
df -h /
echo

# Step 1: Clean APT cache (safe and quick)
echo "Step 1: Cleaning APT cache..."
apt clean
apt autoclean
echo "APT cache cleaned"
echo

# Step 2: Remove old kernels (most effective)
echo "Step 2: Finding old kernels..."
CURRENT_KERNEL=$(uname -r)
echo "Current kernel: $CURRENT_KERNEL"
echo

# List all kernel packages except current
KERNELS_TO_REMOVE=$(dpkg -l | grep '^ii' | grep -E '(pve-kernel|linux-image)' | \
                   grep -v "$CURRENT_KERNEL" | grep -v firmware | grep -v helper | \
                   awk '{print $2}')

if [[ -n "$KERNELS_TO_REMOVE" ]]; then
    echo "Found these old kernels to remove:"
    echo "$KERNELS_TO_REMOVE"
    echo
    
    # Remove them one by one
    for kernel in $KERNELS_TO_REMOVE; do
        echo "Removing: $kernel"
        dpkg --purge "$kernel" 2>/dev/null || apt remove -y "$kernel" 2>/dev/null || true
    done
else
    echo "No old kernels found"
fi
echo

# Step 3: Clean up boot directory manually
echo "Step 3: Cleaning /boot directory..."
# Keep only current kernel files
find /boot -name "*$(uname -r)*" -prune -o \
     -name "vmlinuz*" -o \
     -name "initrd*" -o \
     -name "System.map*" -o \
     -name "config*" \
     -exec rm -f {} \; 2>/dev/null || true
echo "Boot directory cleaned"
echo

# Step 4: Clean logs
echo "Step 4: Cleaning log files..."
# Remove old compressed logs
find /var/log -name "*.gz" -delete 2>/dev/null || true
find /var/log -name "*.old" -delete 2>/dev/null || true
find /var/log -name "*.[0-9]" -delete 2>/dev/null || true

# Clear journal logs
journalctl --vacuum-size=50M 2>/dev/null || true
echo "Logs cleaned"
echo

# Step 5: Remove temporary files
echo "Step 5: Cleaning temporary files..."
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true
echo "Temporary files cleaned"
echo

# Step 6: Final cleanup
echo "Step 6: Final cleanup..."
apt autoremove -y 2>/dev/null || true

# Force remove any leftover packages
dpkg -l | grep '^rc' | awk '{print $2}' | xargs dpkg --purge --force-all 2>/dev/null || true
echo

# Show results
echo -e "${GREEN}Cleanup completed! New disk usage:${NC}"
df -h /
echo

echo -e "${GREEN}Remaining kernels:${NC}"
dpkg -l | grep -E '(pve-kernel|linux-image)' | grep -v firmware
echo

echo -e "${YELLOW}If you still need more space, consider:${NC}"
echo "1. Expanding the root partition: lvextend -L +5G /dev/mapper/pve-root && resize2fs /dev/mapper/pve-root"
echo "2. Checking for large files: find / -type f -size +100M 2>/dev/null | head -10"
echo "3. Moving files to external storage"
