#!/bin/bash

# MySQL-Benutzername, Passwort und andere Verbindungsdetails
MYSQL_PASSWORD=$(cat /vault/mysql/user)
MYSQL_USER=$1
MYSQL_HOST=$2
MYSQL_DATABASE=$3

# Dateien, die die letzten IDs speichern
LAST_ID_FILE_LOGS="/var/www/MISP/last_id_logs.txt"
LAST_ID_FILE_AUDIT="/var/www/MISP/last_id_audit.txt"

# Funktion, um die letzte ID zu laden oder auf 0 zu setzen, wenn die Datei nicht existiert
load_last_id() {
    local file=$1
    if [ -f "$file" ]; then
        cat "$file"
    else
        echo 0
    fi
}

# Lade die letzten IDs
LAST_ID_LOGS=$(load_last_id "$LAST_ID_FILE_LOGS")
LAST_ID_AUDIT=$(load_last_id "$LAST_ID_FILE_AUDIT")

# SQL-Queries, um nur neue Daten zu erhalten
SQL_QUERY_LOGS="SELECT * FROM logs WHERE id > '$LAST_ID_LOGS'"
SQL_QUERY_AUDIT="SELECT * FROM audit_logs WHERE id > '$LAST_ID_AUDIT'"

# Funktion, um eine SQL-Abfrage auszuführen und das Ergebnis mit awk zu formatieren
execute_query() {
    local query=$1
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_DATABASE" -e "$query" --batch --silent | awk 'BEGIN{FS="\t";OFS="|"} {$1=$1; print}'
}

# Führe die SQL-Abfragen aus und formatiere die Ausgabe
execute_query "$SQL_QUERY_LOGS"
execute_query "$SQL_QUERY_AUDIT"

# Aktualisiere die höchsten IDs für das nächste Ausführen
echo "SELECT MAX(id) FROM logs;" | mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_DATABASE" -sN > "$LAST_ID_FILE_LOGS"
echo "SELECT MAX(id) FROM audit_logs;" | mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_DATABASE" -sN > "$LAST_ID_FILE_AUDIT"
