#!/bin/bash
# usage - bash /home/linksnova007/tmp/gen-dkim.sh

USER="linksnova007"
DOMAINS=$(v-list-mail-domains $USER | awk '{if(NR>1)print $1}')

while read -r domain; do
    echo "Processing: $domain"
    # Generate DKIM if not exists
    v-generate-mail-domain-dkim "$USER" "$domain"
    sleep 1
done <<< "$DOMAINS"