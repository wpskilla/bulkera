#!/bin/bash

# https://46.202.194.99:8083/login/
# linksnova007
# Uaemarketinghub786#@!

# Configuration
HESTIA_USER="linksnova007"
IP_ADDR="46.202.194.99"  # replace with your VPS IP address
DOMAINS_FILE="domains.txt"
OUTPUT_DIR="/root/hestia-domain-passwords"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to generate a secure random password
generate_password() {
    tr -dc 'A-Za-z0-9@#$%&*_+=' </dev/urandom | head -c 16
}

# Read each domain from the domains.txt file
while IFS= read -r domain || [[ -n "$domain" ]]; do
    echo "🔧 Processing: $domain"

    password=$(generate_password)
    user="wpadmin"

    # 1. Add the domain (with www alias)
    v-add-web-domain $HESTIA_USER $domain $IP_ADDR
    v-add-web-domain-alias $HESTIA_USER $domain www.$domain

    # 2. Enable mail, DNS, AWStats
    v-add-mail-domain $HESTIA_USER $domain
    v-add-dns-domain $HESTIA_USER $domain $IP_ADDR
    v-add-web-domain-stats $HESTIA_USER $domain awstats

    # 3. Enable SSL, Let's Encrypt, HTTPS redirect, HSTS
    v-add-web-domain-ssl $HESTIA_USER $domain
    v-add-letsencrypt-domain $HESTIA_USER $domain "www.$domain"
    v-change-web-domain-ssl-force $HESTIA_USER $domain yes
    v-change-web-domain-hsts $HESTIA_USER $domain yes

    # 4. Optional: Create FTP/web user if needed (with custom username)
    # Uncomment below if needed
    # v-add-web-domain-ftp $HESTIA_USER $domain $user $password

    # Save credentials
    echo -e "Domain: $domain\nUser: $user\nPassword: $password" > "$OUTPUT_DIR/$domain.txt"

    echo "✅ $domain completed."
    echo "-----------------------------"

done < "$DOMAINS_FILE"

echo "🎉 All domains processed. Passwords saved in: $OUTPUT_DIR"
