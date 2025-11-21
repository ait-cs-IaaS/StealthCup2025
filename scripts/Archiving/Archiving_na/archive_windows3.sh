#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <TEAM_ID>"
    exit 1
fi

TEAM=$1
TIMESTAMP=$(date +%s)

# Define the list of remote hosts and their respective log files or directories
declare -A HOST_LOG_PATHS
HOST_LOG_PATHS["10.0."$TEAM".44"]="C:/Users/%USERNAME%/AppData/Roaming/"
HOST_LOG_PATHS["10.0."$TEAM".29"]="C:/Users/%USERNAME%/AppData/Roaming/"
HOST_LOG_PATHS["10.0."$TEAM".11"]="C:/Users/%USERNAME%/AppData/Roaming/"
HOST_LOG_PATHS["10.0."$TEAM".43"]="C:/Users/%USERNAME%/AppData/Roaming/"
HOST_LOG_PATHS["10.0."$TEAM".59"]="C:/Users/%USERNAME%/AppData/Roaming/"
HOST_LOG_PATHS["10.0."$TEAM".12"]="C:/Users/%USERNAME%/AppData/Roaming/"

# Define the local backup directory
BACKUP_DIR="/home/ubuntu/log_archives/$TEAM""_""$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Define the SSH user
SSH_USER="administrator"  # Replace with your actual SSH username

# Iterate over each host
for HOST in "${!HOST_LOG_PATHS[@]}"; do
    echo "Archiving logs from $HOST..."
    HOST_BACKUP_DIR="$BACKUP_DIR/$HOST"
    mkdir -p "$HOST_BACKUP_DIR"
    
    REMOTE_DIR="$SSH_USER@$HOST:"
    
    # Read log paths into an array
    read -ra LOG_PATHS <<< "${HOST_LOG_PATHS[$HOST]}"
    
    ./paralllel -i windows_logs.txt -d "\n" -t 5 -s "scp -r -i ./stealthcup -o 'StrictHostKeyChecking=no' administrator@$HOST:{0} $HOST_BACKUP_DIR" &

    # Wait for all parallel rsync jobs to complete

done
wait

echo "Log archiving completed."

