#!/usr/bin/env bash

source /utilities.sh

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# set variables
MYSQL_USER=$1
MYSQL_HOST=$2
MYSQL_DATABASE=$3
BACKUP_LIMIT=$4
MYSQL_PORT=3306
MYSQL_PASSWORD_BACKUP=$(cat /vault/mysql/backup)

OutputDirName=${OutputDirName:-/opt/backup}
OutputFileName=${OutputFileName:-MISP-Backup}
OutputFull="${OutputDirName}/${OutputFileName}-$(date '+%Y%m%d_%H%M%S').tar.gz"

# Ensure backup directory exists
mkdir -p "$OutputDirName"

log "Starting MySQL Dump"
mysqldump --opt --host "$MYSQL_HOST" --port "$MYSQL_PORT" -u $MYSQL_USER -p"$MYSQL_PASSWORD_BACKUP" "$MYSQL_DATABASE" > "$OutputDirName/MISPbackupfile.sql"

# Check if mysqldump was successful
if [[ "$?" != "0" ]]; then
  log "MySQLdump failed, aborting."
  exit 1
fi

tar -pzcf "$OutputFull" -C "$OutputDirName" MISPbackupfile.sql

# Remove the SQL dump file after creating the tarball
rm -rf "$OutputDirName/MISPbackupfile.sql"

log "MISP Backup Completed"
log "OutputDir: ${OutputDirName}"
log "FileName: ${OutputFileName}-$(date '+%Y%m%d_%H%M%S').tar.gz"
log "FullName: ${OutputFull}"

# Delete the oldest backup if the number of backups exceeds a certain limit

backup_count=$(ls -1q ${OutputDirName} | wc -l)
if [ "$backup_count" -gt "$BACKUP_LIMIT" ]; then
  oldest_backup=$(ls -1t ${OutputDirName} | tail -n 1)
  log "Deleting oldest backup: $oldest_backup"
  rm -f "$OutputDirName/$oldest_backup"
fi