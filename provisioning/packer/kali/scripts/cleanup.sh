#!/bin/bash

echo "==> Running cleanup on Kali Linux"

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

# Apt cleanup
echo "==> Cleaning up unused packages"
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

# Remove Bash history
echo "==> Removing Bash history"
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/$(logname)/.bash_history

# Clean up log files
echo "==> Cleaning up log files"
find /var/log -type f -exec truncate -s 0 {} \;

# Clear last login information
echo "==> Clearing last login information"
truncate -s 0 /var/log/lastlog
truncate -s 0 /var/log/wtmp
truncate -s 0 /var/log/btmp

# Clear out swap (if it exists) and disable it until reboot
echo "==> Clearing swap (if available)"
swap_partition=$(swapon --show=NAME --noheadings | head -n 1)

if [[ -n "$swap_partition" ]]; then
    swapoff "$swap_partition"
    dd if=/dev/zero of="$swap_partition" bs=1M status=progress || echo "dd exit code $? is suppressed"
    mkswap "$swap_partition"
else
    echo "No swap partition found, skipping swap cleanup."
fi

# Sync changes to disk
sync

# Show disk usage after cleanup
echo "==> Disk usage after cleanup"
df -h