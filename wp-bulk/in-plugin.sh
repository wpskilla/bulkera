#!/bin/bash
# bash /home/linksnova007/tmp/in-plugin/in-plugin.sh

# Configuration from previous setup
HESTIA_USER="linksnova007"
PLUGIN_PATH="/home/linksnova007/tmp/in-plugin/all-in-one-wp-migration-old.zip"

DOMAINS=(
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

# Main plugin installation loop
for DOMAIN in "${DOMAINS[@]}"; do
  WEB_DIR="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
  
  echo "➤ Processing domain: ${DOMAIN}"
  
  if [ -d "${WEB_DIR}" ]; then
    echo "   Installing migration plugin..."
    
    # Install and activate plugin
    sudo -u "${HESTIA_USER}" wp plugin install "${PLUGIN_PATH}" --activate --path="${WEB_DIR}"
    
    echo "   ✔ Plugin installed successfully"
  else
    echo "   ❗ WordPress directory not found: ${WEB_DIR}"
  fi
  
  echo "----------------------------------------"
done

echo "Bulk plugin installation complete!"