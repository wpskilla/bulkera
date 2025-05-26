#!/bin/bash
# Fixed version handling line endings without dos2unix
# Usage: bash /home/linksnova007/tmp/domains/v-domain-add-v2.sh

# Configuration
USER="linksnova007"
IP="46.202.194.99"
DOMAIN_LIST="/home/linksnova007/tmp/domains/domains.txt"
LOG_FILE="/home/linksnova007/tmp/domains/domain_addition.log"

# Check prerequisites
if [ ! -f "$DOMAIN_LIST" ]; then
    echo "ERROR: Domain list missing: $DOMAIN_LIST" | tee -a "$LOG_FILE"
    exit 1
fi

# Convert line endings using native tools (replaces dos2unix)
sed -i 's/\r$//' "$DOMAIN_LIST"  # Remove Windows-style CRLF endings

# Verify file content
if ! grep -q . "$DOMAIN_LIST"; then
    echo "ERROR: Domain list is empty" | tee -a "$LOG_FILE"
    exit 1
fi

# Clear previous logs
: > "$LOG_FILE"

# Pre-check DNS conflicts
echo "Checking DNS prerequisites..." | tee -a "$LOG_FILE"
while IFS= read -r domain; do
    [[ -z "${domain// }" ]] && continue
    
    # Check domain format
    if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo "INVALID DOMAIN FORMAT: $domain" | tee -a "$LOG_FILE"
        exit 1
    fi

done < "$DOMAIN_LIST"

# Main processing
echo "Starting domain additions..." | tee -a "$LOG_FILE"
mapfile -t DOMAINS < "$DOMAIN_LIST"

for domain in "${DOMAINS[@]}"; do
    [[ -z "$domain" ]] && continue

    echo "Processing: $domain" | tee -a "$LOG_FILE"
    
    LANG=C.UTF-8 v-add-domain "$USER" "$domain" "$IP" 'yes' 'no' 'no' 'no' 'no' 'yes' 'yes' 'yes' 'no' 'yes' >> "$LOG_FILE" 2>&1 </dev/null

    case $? in
        0) echo "SUCCESS: $domain created" | tee -a "$LOG_FILE" ;;
        1) echo "ERROR: $domain exists" | tee -a "$LOG_FILE" ;;
        2) echo "CONFIG ERROR: $domain" | tee -a "$LOG_FILE" ;;
        *) echo "UNKNOWN ERROR: $domain" | tee -a "$LOG_FILE" ;;
    esac

    sleep 2
done

echo "Process completed. Full log: $LOG_FILE"
