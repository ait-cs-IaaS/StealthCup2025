#!/bin/bash

TEAM=2
TIMESTAMP=$(date +%s)

# Define the list of remote hosts and their respective log files or directories
declare -A HOST_LOG_PATHS
# Boilerplate logs
#HOST_LOG_PATHS["10.0.2.60"]="/var/log/syslog /var/log/amazon/ssm/* /var/log/apt/* /var/log/auth.log /var/log/dmesg /var/log/dpkg.log /var/log/journal /var/log/kern.log /var/log/lastlog* /var/log/wtmp* /var/log/utmp* /var/log/btmp* /home/*/.bash_history /root/.bash_history /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/*  /var/ossec/stats/* /var/log/wazuh-passwords-tool.log "

HOST_LOG_PATHS["10.0."$TEAM".10"]="/var/log/syslog /var/log/amazon/ssm/* /var/log/apt/* /var/log/auth.log /var/log/dmesg /var/log/dpkg.log /var/log/journal /var/log/kern.log /var/log/lastlog* /var/log/wtmp* /var/log/utmp* /var/log/btmp* /home/*/.bash_history /root/.bash_history /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/*  /var/ossec/stats/* /var/log/wazuh-passwords-tool.log /var/log/filebeat/* /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/* /var/ossec/stats/* /var/log/wazuh-passwords-tool.log"
#HOST_LOG_PATHS["10.0.2.60"]="/var/log/syslog /var/log/amazon/ssm/* /var/log/apt/* /var/log/auth.log /var/log/dmesg /var/log/dpkg.log /var/log/journal /var/log/kern.log /var/log/lastlog* /var/log/wtmp* /var/log/utmp* /var/log/btmp* /home/*/.bash_history /root/.bash_history /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/*  /var/ossec/stats/* /var/log/wazuh-passwords-tool.log /opt/scadalts/mysql/server/data/* /opt/scadalts/mysql/server/mysqld.log /opt/scadalts/tomcat/server/logs/*"
#HOST_LOG_PATHS["10.0.2.73"]="/var/log/syslog /var/log/amazon/ssm/* /var/log/apt/* /var/log/auth.log /var/log/dmesg /var/log/dpkg.log /var/log/journal /var/log/kern.log /var/log/lastlog* /var/log/wtmp* /var/log/utmp* /var/log/btmp* /home/*/.bash_history /root/.bash_history /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/*  /var/ossec/stats/* /var/log/wazuh-passwords-tool.log "
#HOST_LOG_PATHS["10.0.2.45"]="/var/log/syslog /var/log/amazon/ssm/* /var/log/apt/* /var/log/auth.log /var/log/dmesg /var/log/dpkg.log /var/log/journal /var/log/kern.log /var/log/lastlog* /var/log/wtmp* /var/log/utmp* /var/log/btmp* /home/*/.bash_history /root/.bash_history /var/log/osquery/* /var/log/wazuh-indexer/* /var/ossec/logs/* /var/ossec/queue/vd_updater/rocksdb/updater_vulnerability_feed_manager_metadata/* /var/ossec/queue/*  /var/ossec/stats/* /var/log/wazuh-passwords-tool.log /opt/VendorEDR/*.sys /var/log/edr-* /home/*/.influx* /var/lib/influxdb/ /var/log/grafana/grafana.log /var/lib/grafana/*"




# Define the local backup directory
BACKUP_DIR="$HOME/log_archives/$TEAM""_""$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Define the SSH user
SSH_USER="ubuntu"  # Replace with your actual SSH username

# Iterate over each host
for HOST in "${!HOST_LOG_PATHS[@]}"; do
    echo "Archiving logs from $HOST..."
    HOST_BACKUP_DIR="$BACKUP_DIR/$HOST"
    mkdir -p "$HOST_BACKUP_DIR"
    
    REMOTE_DIR="$SSH_USER@$HOST:"
    
    # Read log paths into an array
    read -ra LOG_PATHS <<< "${HOST_LOG_PATHS[$HOST]}"
    
    # Iterate over each log path specific to the host
    for LOG_PATH in "${LOG_PATHS[@]}"; do
        RSYNC_DEST="$HOST_BACKUP_DIR/$(basename "$LOG_PATH")"
        
	rsync -avz -e "ssh -J jump_cup -p 22" --rsync-path="sudo rsync" --protect-args "$REMOTE_DIR""$LOG_PATH" "$RSYNC_DEST"

    done

done

echo "Log archiving completed."

