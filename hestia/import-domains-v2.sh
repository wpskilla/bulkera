#!/bin/bash

# Enhanced domain import script for HestiaCP
# Author: SysOps Assistant
# Version: 1.3

# Configuration
HESTIA_USER="linksnova007"
IP_ADDR="46.202.194.99"
DOMAINS_FILE="/home/linksnova007/tmp/domains-2.txt"
OUTPUT_DIR="/home/linksnova007/tmp/domain-passwords"
HESTIA_BIN="/usr/local/hestia/bin"
LOG_FILE="/home/linksnova007/tmp/logs/import-$(date +%Y%m%d%H%M%S).log"

# Ensure required directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to generate secure random password
generate_password() {
    tr -dc 'A-Za-z0-9@#$%&*_+=' </dev/urandom | head -c 16
}

# Function to check command success
check_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error: $1 failed${NC}"
        return 1
    fi
}

# Verify Hestia CLI availability
verify_hestia_commands() {
    local required_commands=(
        v-list-web-domain
        v-delete-web-domain
        v-add-web-domain
        v-add-web-domain-alias
        v-add-mail-domain
        v-add-dns-domain
        v-add-web-domain-ssl
        v-add-letsencrypt-domain
        v-add-web-domain-ssl-force
        v-add-web-domain-ssl-hsts
        v-delete-web-domain-ssl-hsts
    )

    for cmd in "${required_commands[@]}"; do
        if [ ! -f "$HESTIA_BIN/$cmd" ]; then
            echo -e "${RED}❌ Critical Error: Missing required command $cmd${NC}"
            exit 1
        fi
    done
}

# Domain cleanup function
clean_domain() {
    local domain=$1
    echo -e "${YELLOW}⚠️ Cleaning up existing domain: $domain${NC}"
    
    "$HESTIA_BIN"/v-delete-web-domain "$HESTIA_USER" "$domain" "yes"
    check_success "Domain removal"
    
    "$HESTIA_BIN"/v-delete-dns-domain "$HESTIA_USER" "$domain" "yes"
    "$HESTIA_BIN"/v-delete-mail-domain "$HESTIA_USER" "$domain" "yes"

    local web_dir="/home/$HESTIA_USER/web/$domain"
    [ -d "$web_dir" ] && rm -rf "$web_dir"
}

# Main domain processing
process_domain() {
    local domain=$1
    local password=$(generate_password)
    local user="$HESTIA_USER"
    
    echo -e "\n${GREEN}🔧 Processing domain: $domain${NC}"
    
    # Check and clean existing domain
    if "$HESTIA_BIN"/v-list-web-domain "$HESTIA_USER" "$domain" &>/dev/null; then
        clean_domain "$domain"
    fi

    # Add web domain
    if ! "$HESTIA_BIN"/v-add-web-domain "$HESTIA_USER" "$domain" "$IP_ADDR"; then
        echo -e "${RED}❌ Critical Error: Failed to add web domain${NC}"
        return 1
    fi

    # Add www alias
    if ! "$HESTIA_BIN"/v-list-web-domain "$HESTIA_USER" "www.$domain" &>/dev/null; then
        "$HESTIA_BIN"/v-add-web-domain-alias "$HESTIA_USER" "$domain" "www.$domain"
        check_success "WWW alias addition"
    else
        echo -e "${YELLOW}ℹ️ www.$domain alias already exists${NC}"
    fi

    # Add supporting services
    "$HESTIA_BIN"/v-add-mail-domain "$HESTIA_USER" "$domain"
    check_success "Mail domain addition"

    "$HESTIA_BIN"/v-add-dns-domain "$HESTIA_USER" "$domain" "$IP_ADDR"
    check_success "DNS domain addition"

    echo "🛠 Configuring SSL..."

    "$HESTIA_BIN"/v-add-web-domain-ssl "$HESTIA_USER" "$domain"
    check_success "SSL base configuration"

    "$HESTIA_BIN"/v-add-letsencrypt-domain "$HESTIA_USER" "$domain" "www.$domain"
    check_success "Let's Encrypt certificate generation"

    "$HESTIA_BIN"/v-add-web-domain-ssl-force "$HESTIA_USER" "$domain" "yes"
    check_success "SSL enforcement"

    # Enable HSTS
    "$HESTIA_BIN"/v-add-web-domain-ssl-hsts "$HESTIA_USER" "$domain"
    check_success "HSTS configuration"

    # Save credentials
    echo -e "Domain: $domain\nUser: $user\nPassword: $password" > "$OUTPUT_DIR/$domain.txt"
    echo -e "${GREEN}✅ Successfully configured $domain${NC}"
}

# Main execution
verify_hestia_commands

echo -e "\n${GREEN}🚀 Starting domain import process at $(date)${NC}"
echo -e "📄 Domain list: $DOMAINS_FILE"
echo -e "📂 Output directory: $OUTPUT_DIR"
echo -e "📋 Log file: $LOG_FILE\n"

while IFS= read -r domain || [[ -n "$domain" ]]; do
    domain=$(echo "$domain" | xargs)
    [[ -z "$domain" ]] && continue
    
    process_domain "$domain"
    echo "------------------------------"
done < "$DOMAINS_FILE"

echo -e "\n${GREEN}🎉 All domains processed successfully!${NC}"
echo -e "🔐 Passwords saved in: $OUTPUT_DIR"
echo -e "📋 Detailed log available at: $LOG_FILE"
