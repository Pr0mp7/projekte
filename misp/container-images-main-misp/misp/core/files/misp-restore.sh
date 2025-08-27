#!/usr/bin/env bash

# set MYSQL variables from files or defaults
[ -z "$MYSQL_HOST" ] && MYSQL_HOST=db
[ -z "$MYSQL_PORT" ] && MYSQL_PORT=3306
[ -z "$MYSQL_USER" ] && MYSQL_USER=backup
[ -z "$MYSQL_PASSWORD_FILE_BACKUP" ] && MYSQL_PASSWORD_BACKUP=AE!4yLJkR!r96vBh || MYSQL_PASSWORD_BACKUP=`< $MYSQL_PASSWORD_FILE_BACKUP`
[ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE=misp

if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/backupfile.tar.gz"
    exit 1
fi

BackupFile=$1

if [ ! -f "$BackupFile" ]; then
    echo "Backup file $BackupFile does not exist."
    exit 1
fi

RestoreDir="/opt/backup"

# Ensure restore directory exists
mkdir -p "$RestoreDir"

echo "Extracting backup file"
tar -pzxf "$BackupFile" -C "$RestoreDir"

# Find the SQL dump file
SqlFile=$(find "$RestoreDir" -name '*.sql')

if [ -z "$SqlFile" ]; then
    echo "No SQL dump file found in the backup."
    exit 1
fi

echo "Restoring MySQL database"
mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" -u "backup" -p"$MYSQL_PASSWORD_BACKUP" "$MYSQL_DATABASE" < "$SqlFile"

# Check if the MySQL restore was successful
if [[ "$?" != "0" ]]; then
    echo "MySQL restore failed, aborting." && exit 1
fi

# Clean up the SQL dump file after successful restore
rm -rf "$SqlFile"

echo "MISP Restore Completed"
