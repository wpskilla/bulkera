#!/bin/bash
# bash /home/linksnova007/tmp/bulk-wp-install-v2.sh

# Configuration
ADMIN_USER="uaemarketinghub786"
ADMIN_PASSWORD="Dubai007@!"
ADMIN_EMAIL="uaemarketinghub786@gmail.com"
WP_TITLE="Site Title"
# PLUGINS="elementor"
THEME="hello-elementor"
HESTIA_USER="linksnova007"
PLUGIN_PATH="/home/linksnova007/tmp/in-plugin/all-in-one-wp-migration-old.zip"


DOMAINS=(
chartered-surveyor.org.uk
house-clearance-company.uk
mould-treatment.uk
)

# Improved database name generator with full domain encoding
generate_db_base() {
  local domain="$1"
  # Convert domain to lowercase, replace dots with underscores, remove special chars
  echo "$domain" | tr '[:upper:]' '[:lower:]' | tr '.' '_' | tr -cd '[:alnum:]_' | cut -c1-50
}

# Database user generator with full domain encoding
generate_db_user() {
  local domain="$1"
  # Create unique user name with hash suffix
  echo "$domain" | md5sum | cut -c1-8
}

# Main installation loop
for DOMAIN in "${DOMAINS[@]}"; do
  WEB_DIR="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
  DB_BASE=$(generate_db_base "$DOMAIN")
  DB_USER=$(generate_db_user "$DOMAIN")
  DB_PASSWORD=$(openssl rand -hex 12 | cut -c1-16)
  
  # Hestia-prefixed credentials
  HESTIA_DB_NAME="${HESTIA_USER}_${DB_BASE}"
  HESTIA_DB_USER="${HESTIA_USER}_${DB_USER}"

  echo "➤ Processing domain: ${DOMAIN}"
  echo "   Final Database: ${HESTIA_DB_NAME}"
  echo "   Final DB User: ${HESTIA_DB_USER}"

  # Create database
  echo "   Creating database..."
  if ! sudo /usr/local/hestia/bin/v-add-database "${HESTIA_USER}" "${DB_BASE}" "${DB_USER}" "${DB_PASSWORD}" mysql localhost; then
    echo "   ❗ Database creation failed, skipping..."
    continue
  fi

  # Verify database exists
  if ! sudo mysql -e "USE ${HESTIA_DB_NAME}"; then
    echo "   ❗ Database verification failed, cleaning up..."
    sudo /usr/local/hestia/bin/v-delete-database "${HESTIA_USER}" "${DB_BASE}"
    continue
  fi

  # Clean existing installation
  echo "   Cleaning directory..."
  sudo -u "${HESTIA_USER}" -- bash -c "rm -rf ${WEB_DIR}/* ${WEB_DIR}/.??* 2> /dev/null"
  sudo -u "${HESTIA_USER}" mkdir -p "${WEB_DIR}"

  # WordPress installation
  echo "   Installing WordPress..."
  sudo -u "${HESTIA_USER}" wp core download --path="${WEB_DIR}"
  
  sudo -u "${HESTIA_USER}" wp config create \
    --dbname="${HESTIA_DB_NAME}" \
    --dbuser="${HESTIA_DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --path="${WEB_DIR}"

  # Final installation
  sudo -u "${HESTIA_USER}" wp core install \
    --url="${DOMAIN}" \
    --title="${WP_TITLE}" \
    --admin_user="${ADMIN_USER}" \
    --admin_password="${ADMIN_PASSWORD}" \
    --admin_email="${ADMIN_EMAIL}" \
    --path="${WEB_DIR}"

  # sudo -u "${HESTIA_USER}" wp plugin install ${PLUGINS} --activate --path="${WEB_DIR}"
  sudo -u "${HESTIA_USER}" wp plugin install "${PLUGIN_PATH}" --activate --path="${WEB_DIR}"
  sudo -u "${HESTIA_USER}" wp theme install ${THEME} --activate --path="${WEB_DIR}"

  echo "   ✔ ${DOMAIN} installation completed"
  echo "----------------------------------------"
done

echo "Bulk WordPress installation complete!"