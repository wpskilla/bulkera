#!/bin/bash
# bash /home/linksnova007/tmp/backups/backup-place-v2.sh

# Configuration
HESTIA_USER="linksnova007"
BACKUP_FILE="garden-rooms.org.uk-20250520-051400-936.wpress"
SOURCE_DIR="/home/${HESTIA_USER}/tmp/backups"
DEST_DIR_SUFFIX="wp-content/ai1wm-backups"
MAX_PARALLEL=2  # Number of parallel operations (adjust based on server resources)
DELAY=1         # Base delay between batches in seconds

DOMAINS=(
awninginstallation.co.uk
bathroomfitters.org.uk
bathroom-installation.co.uk
bathroommouldremoval.co.uk
bathroom-refurb.uk
bathroomremodelling.co.uk
bathroomrepair.co.uk
bathroomtilers.uk
bedassembly.co.uk
bedbugremoval.uk
bedbugtreatment.uk
fencepanelrepair.uk
fakegrassinstaller.uk
bestplumbingservice.co.uk
bereavementclearance.co.uk
)

# Smart throttling function
throttle() {
  while [ $(jobs -p | wc -l) -ge $MAX_PARALLEL ]; do
    sleep 1
  done
}

# Main processing function
process_domain() {
  local DOMAIN=$1
  WEB_ROOT="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
  DEST_DIR="${WEB_ROOT}/${DEST_DIR_SUFFIX}"
  
  echo "➤ Processing domain: ${DOMAIN} [PID: $$]"
  
  # Create backup directory if not exists
  if [ ! -d "${DEST_DIR}" ]; then
    echo "Creating AIO backup directory..."
    sudo -u "${HESTIA_USER}" mkdir -p "${DEST_DIR}"
    sleep 0.5  # Brief FS sync pause
  fi
  
  # Verify source backup exists
  if [ ! -f "${SOURCE_DIR}/${BACKUP_FILE}" ]; then
    echo "❗ Critical Error: Source backup file not found!"
    exit 1
  fi

  # Copy backup with proper permissions
  echo "Deploying backup file..."
  sudo -u "${HESTIA_USER}" cp "${SOURCE_DIR}/${BACKUP_FILE}" "${DEST_DIR}/"
  
  # Verify copy success
  if [ $? -eq 0 ]; then
    echo "✔ Backup deployed successfully"
    
    # Set safe permissions
    sudo -u "${HESTIA_USER}" chmod 644 "${DEST_DIR}/${BACKUP_FILE}"
    sudo find "${DEST_DIR}" -type d -exec chmod 755 {} \;
  else
    echo "❗ Backup copy failed for ${DOMAIN}"
  fi
  
  echo "----------------------------------------"
}

# Execution with smart resource management
(
for DOMAIN in "${DOMAINS[@]}"; do
  throttle
  process_domain "$DOMAIN" &
  sleep $((DELAY + RANDOM % 2))  # Randomized delay between 3-4 seconds
done
wait
)

echo "Backup deployment complete! Total domains processed: ${#DOMAINS[@]}"
echo "Access backups via: WordPress Admin → All-in-One WP Migration → Backups"
