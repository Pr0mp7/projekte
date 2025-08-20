#!/bin/bash
# pull_and_save_shuffle_images.sh

set -e

# Konfiguration
EXPORT_DIR="shuffle-2.0.0-export"
ARCHIVE_NAME="shuffle-2.0.0-complete.tar.gz"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Shuffle 2.0.0 Images Download Script ===${NC}"

# Verzeichnis erstellen
echo -e "${YELLOW}Erstelle Export-Verzeichnis: $EXPORT_DIR${NC}"
mkdir -p $EXPORT_DIR

# Array der Shuffle 2.0.0 Images
IMAGES=(
    "ghcr.io/shuffle/shuffle-backend:2.0.0"
    "ghcr.io/shuffle/shuffle-frontend:2.0.0"
    "ghcr.io/shuffle/shuffle-orborus:2.0.0"
    "ghcr.io/shuffle/shuffle-worker:2.0.0"
    "frikky/shuffle:app_sdk"
    "opensearchproject/opensearch:2.5.0"
    "frikky/shuffle:shuffle-subflow_1.0.0"
)

# Funktionen
pull_and_save() {
    local image=$1
    local file_name=$(echo $image | sed 's/:/-/g' | sed 's/\//-/g')
    local file_path="$EXPORT_DIR/${file_name}.tar"
    
    echo -e "${YELLOW}Pulle Image: $image${NC}"
    if docker pull $image; then
        echo -e "${YELLOW}Speichere als: $file_path${NC}"
        if docker save $image -o $file_path; then
            echo -e "${GREEN}✓ Erfolgreich gespeichert: $file_path${NC}"
        else
            echo -e "${RED}✗ Fehler beim Speichern von $image${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Fehler beim Pullen von $image${NC}"
        return 1
    fi
    echo ""
}

# Images pullen und speichern
echo -e "${GREEN}Beginne mit dem Pullen und Speichern der Images...${NC}"
for image in "${IMAGES[@]}"; do
    pull_and_save "$image"
done

# Gesamtarchiv erstellen
echo -e "${YELLOW}Erstelle Gesamtarchiv: $ARCHIVE_NAME${NC}"
tar czf $ARCHIVE_NAME $EXPORT_DIR/

# Zusammenfassung
echo -e "${GREEN}=== Zusammenfassung ===${NC}"
echo -e "Gespeicherte Images:"
ls -lh $EXPORT_DIR/*.tar
echo ""
echo -e "Gesamtarchiv: ${GREEN}$ARCHIVE_NAME${NC}"
ls -lh $ARCHIVE_NAME

echo -e "${GREEN}✓ Alle Shuffle 2.0.0 Images wurden erfolgreich heruntergeladen und gespeichert!${NC}"

