#!/bin/bash
# usage - bash /home/linksnova007/tmp/dkim_records.sh

USER="linksnova007"
HESTIA_BIN="/usr/local/hestia/bin"
OUTPUT_FILE="/home/linksnova007/tmp/outs/dkim_records.txt"

echo "domain,type,content" > "$OUTPUT_FILE"

# Get all mail domains
DOMAINS=$($HESTIA_BIN/v-list-mail-domains $USER | awk 'NR>1 {print $1}')

while read -r domain; do
    echo "Processing: $domain"
    
    # Get DKIM DNS records
    $HESTIA_BIN/v-list-mail-domain-dkim-dns $USER $domain | while read -r line; do
        if [[ $line == *"TXT"* && $line == *"mail._domainkey"* ]]; then
            # Parse DNS record components
            name=$(echo "$line" | awk '{print $2}' | sed 's/\.$//')
            content=$(echo "$line" | awk -F'"' '{print $2}')
            
            # Format output exactly as required
            echo "$domain, $name, $content" >> "$OUTPUT_FILE"
        fi
    done
done <<< "$DOMAINS"

echo "Export completed: $OUTPUT_FILE"
