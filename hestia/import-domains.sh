#!/bin/bash

# run up
# chmod +x /home/linksnova007/tmp/import-domains.sh
# /home/linksnova007/tmp/import-domains.sh
# /home/linksnova007/tmp/import-domains.sh > /home/linksnova007/tmp/import.log 2>&1

# Configuration
HESTIA_USER="linksnova007"
IP_ADDR="46.202.194.99"
DOMAINS_FILE="/home/linksnova007/tmp/domains-2.txt"
OUTPUT_DIR="/home/linksnova007/tmp/domain-passwords"
HESTIA_BIN="/usr/local/hestia/bin/"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to generate secure random password
generate_password() {
    tr -dc 'A-Za-z0-9@#$%&*_+=' </dev/urandom | head -c 16
}

# Check if Hestia commands are available
if [ ! -d "$HESTIA_BIN" ]; then
    echo "❌ Error: Hestia CLI not found at $HESTIA_BIN"
    exit 1
fi

# Read domains file
while IFS= read -r domain || [[ -n "$domain" ]]; do
    echo "🔧 Processing: $domain"
    
    # Check if domain exists
    if $HESTIA_BIN/v-list-web-domain $HESTIA_USER $domain &>/dev/null; then
        echo "⚠️ Domain exists - cleaning up..."
        
        # Remove existing domain and all associated services
        $HESTIA_BIN/v-delete-web-domain $HESTIA_USER $domain "yes"
        
        # Additional cleanup for any remaining files
        web_dir="/home/$HESTIA_USER/web/$domain"
        if [ -d "$web_dir" ]; then
            rm -rf "$web_dir"
            echo "🧹 Removed residual files for $domain"
        fi
    fi

    password=$(generate_password)
    user="linksnova007"

    # Add domain with error handling
    if ! $HESTIA_BIN/v-add-web-domain $HESTIA_USER $domain $IP_ADDR; then
        echo "❌ Failed to add web domain: $domain"
        continue
    fi

    # Add www alias
    $HESTIA_BIN/v-add-web-domain-alias $HESTIA_USER $domain "www.$domain"

    # Enable additional services
    $HESTIA_BIN/v-add-mail-domain $HESTIA_USER $domain
    $HESTIA_BIN/v-add-dns-domain $HESTIA_USER $domain $IP_ADDR
    $HESTIA_BIN/v-add-web-domain-stats $HESTIA_USER $domain "awstats"

    # SSL Configuration
    $HESTIA_BIN/v-add-web-domain-ssl $HESTIA_USER $domain
    $HESTIA_BIN/v-add-letsencrypt-domain $HESTIA_USER $domain "www.$domain"
    $HESTIA_BIN/v-change-web-domain-ssl-force $HESTIA_USER $domain "yes"
    $HESTIA_BIN/v-change-web-domain-hsts $HESTIA_USER $domain "yes"

    # Create FTP user (uncomment if needed)
    # if ! $HESTIA_BIN/v-add-web-domain-ftp $HESTIA_USER $domain $user $password; then
    #     echo "❌ Failed to create FTP user for $domain"
    # fi

    # Save credentials
    echo -e "Domain: $domain\nUser: $user\nPassword: $password" > "$OUTPUT_DIR/$domain.txt"

    echo "✅ $domain completed."
    echo "-----------------------------"

done < "$DOMAINS_FILE"

echo "🎉 All domains processed. Passwords saved in: $OUTPUT_DIR"