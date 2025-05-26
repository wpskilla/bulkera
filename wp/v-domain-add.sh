#!/bin/bash
# Script to bulk add domains to HestiaCP
# Usage: bash /home/linksnova007/tmp/domains/v-domain-add.sh

# Configuration
USER="linksnova007"
IP="46.202.194.99"
DOMAIN_LIST="/home/linksnova007/tmp/domains/domains.txt"
LOG_FILE="/home/linksnova007/tmp/domains/domain_addition.log"

# Check if domain list exists
if [ ! -f "$DOMAIN_LIST" ]; then
    echo "ERROR: Domain list file not found: $DOMAIN_LIST" | tee -a "$LOG_FILE"
    exit 1
fi

# Convert line endings to Unix (in case file was created on Windows)
dos2unix "$DOMAIN_LIST" 2>/dev/null

# Clear previous log
> "$LOG_FILE"

echo "Starting bulk domain addition..." | tee -a "$LOG_FILE"

# Loop through domains
while IFS= read -r domain; do
    # Skip empty or whitespace-only lines
    if [[ -z "${domain// }" ]]; then
        continue
    fi

    echo "Processing: $domain" | tee -a "$LOG_FILE"

    # Add domain using Hestia CLI (redirect stdin to /dev/null)
    v-add-domain "$USER" "$domain" "$IP" 'yes' 'no' 'no' 'no' 'no' '' '' 'yes' 'no' 'yes' >> "$LOG_FILE" 2>&1 </dev/null

    # Check exit status
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Added $domain" | tee -a "$LOG_FILE"
    else
        echo "ERROR: Failed to add $domain (check logs)" | tee -a "$LOG_FILE"
    fi

    # Short pause to avoid overwhelming the server
    sleep 2
done < "$DOMAIN_LIST"

echo "Bulk domain addition completed. Check log: $LOG_FILE"