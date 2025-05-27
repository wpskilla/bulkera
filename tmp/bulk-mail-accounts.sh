#!/bin/bash
# bulk-mail-accounts.sh
# Usage: sudo bash /home/linksnova007/tmp/bulk-mail-accounts.sh

# Configuration
HESTIA_USER="linksnova007"
MAIL_USER="contact"
FIXED_PASSWORD="Dubai007@!"
LOG_DIR="/home/${HESTIA_USER}/tmp/logs"
LOG_FILE="${LOG_DIR}/mail_accounts.log"
SLEEP_TIME=1  # Seconds between domain processing

# Domains list - update this array with your actual domains
DOMAINS=(
    greenhouseremoval.uk
    gutter-cleaners.uk
    gutterinstallers.co.uk
    gutter-repair.uk
    gutterunblocking.uk
    hardwoodfloorsanding.uk
    hippobagcollection.co.uk
    hoarderhouseclearance.co.uk
    summer-houses.co.uk
    summer-houses.uk
    tapeandjointer.uk
    thatchedroofing.org.uk
    windowrespraying.co.uk
    woodendoorfitters.co.uk
    woodflooringfitters.co.uk
)

# Create log directory if not exists
mkdir -p "$LOG_DIR"

# Initialize log file
echo "Domain,Status,Message" > "$LOG_FILE"

# Main processing loop with enhanced error handling
for DOMAIN in "${DOMAINS[@]}"; do
    echo "Processing: $DOMAIN"
    
    # Create mail account with fixed credentials
    OUTPUT=$(sudo /usr/local/hestia/bin/v-add-mail-account "$HESTIA_USER" "$DOMAIN" "$MAIL_USER" "$FIXED_PASSWORD" 2>&1)
    RESULT=$?
    
    # Log results
    if [ $RESULT -eq 0 ]; then
        echo "$DOMAIN,SUCCESS,Account created" >> "$LOG_FILE"
        echo "✅ Created ${MAIL_USER}@${DOMAIN}"
    else
        ERROR_MSG=$(echo "$OUTPUT" | tail -n 1 | tr -d '\n' | tr ',' ';')  # Make CSV safe
        echo "$DOMAIN,ERROR,\"$ERROR_MSG\"" >> "$LOG_FILE"
        echo "❌ Failed ${MAIL_USER}@${DOMAIN}: $ERROR_MSG"
    fi
    
    # Regulated sleep between operations
    sleep "$SLEEP_TIME"
done

echo "Processing complete!"
echo "Log file: $LOG_FILE"