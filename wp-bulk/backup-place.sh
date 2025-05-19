#!/bin/bash
# bash /home/linksnova007/tmp/backups/backup-place.sh

# Configuration
HESTIA_USER="linksnova007"
BACKUP_FILE="garden-rooms.org.uk-20250519-000952-942.wpress"
SOURCE_DIR="/home/${HESTIA_USER}/tmp/backups"
DEST_DIR_SUFFIX="wp-content/ai1wm-backups"

DOMAINS=(
  gardenjunkremoval.co.uk
  gardenrubbishremoval.co.uk
  gardenrubbishremoval.uk
  gardenshedclearance.co.uk
  gardenshedclearance.uk
  gardenshedremoval.co.uk
  gardenshedremoval.uk
  gardenwallbuilders.co.uk
  gardenwastedisposal.co.uk
  gardenwasteremoval.uk
  gazeboinstallation.uk
  generalwasteremoval.co.uk
  grass-cutting.org.uk
  grasslayers.co.uk
  graveldriveways.uk
  greaseextractioncleaning.co.uk
  greenhousebuilders.uk
)

# Main backup placement loop
for DOMAIN in "${DOMAINS[@]}"; do
  WEB_ROOT="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
  DEST_DIR="${WEB_ROOT}/${DEST_DIR_SUFFIX}"
  
  echo "➤ Processing domain: ${DOMAIN}"
  
  # Create backup directory if not exists
  if [ ! -d "${DEST_DIR}" ]; then
    echo "   Creating AIO backup directory..."
    sudo -u "${HESTIA_USER}" mkdir -p "${DEST_DIR}"
  fi
  
  # Verify source backup exists
  if [ ! -f "${SOURCE_DIR}/${BACKUP_FILE}" ]; then
    echo "   ❗ Critical Error: Source backup file not found!"
    exit 1
  fi

  # Copy backup with proper permissions
  echo "   Deploying backup file..."
  sudo -u "${HESTIA_USER}" cp "${SOURCE_DIR}/${BACKUP_FILE}" "${DEST_DIR}/"
  
  # Verify copy success
  if [ $? -eq 0 ]; then
    echo "   ✔ Backup deployed successfully"
    
    # Set safe permissions (All-in-One WP Migration v6.77 requirements)
    sudo -u "${HESTIA_USER}" chmod 644 "${DEST_DIR}/${BACKUP_FILE}"
    sudo find "${DEST_DIR}" -type d -exec chmod 755 {} \;
  else
    echo "   ❗ Backup copy failed for ${DOMAIN}"
  fi
  
  echo "----------------------------------------"
done

echo "Backup deployment complete! Access backups via:"
echo "WordPress Admin → All-in-One WP Migration → Backups"