#!/bin/bash

# Configuration
ADMIN_USER="uaemarketinghub786"
ADMIN_PASSWORD="Dubai007@!"
ADMIN_EMAIL="uaemarketinghub786@gmail.com"
WP_TITLE="Site Title"
PLUGINS="elementor"
THEME="hello-elementor"
HESTIA_USER="linksnova007"
MAX_RETRIES=3
SLEEP_DURATION=10

DOMAINS=(
  gardenwallbuilders.co.uk
  gardenwastedisposal.co.uk
  gardenwasteremoval.uk
)

# Database name generator (Hestia will auto-prefix)
generate_db_name() {
  echo "$(echo "$1" | tr -d '.' | cut -c1-12)"
}

# Database user generator (Hestia will auto-prefix)
generate_db_user() {
  echo "$(echo "$1" | tr -d '.' | cut -c1-16)"
}

# Main installation loop
for DOMAIN in "${DOMAINS[@]}"; do
  WEB_DIR="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
  DB_BASE=$(generate_db_name "$DOMAIN")
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

  # Verify user privileges
  if ! sudo mysql -e "SHOW GRANTS FOR '${HESTIA_DB_USER}'@'localhost'" &> /dev/null; then
    echo "   ❗ User privileges missing, cleaning up..."
    sudo /usr/local/hestia/bin/v-delete-database "${HESTIA_USER}" "${DB_BASE}"
    continue
  fi

  # WordPress installation
  sudo -u "${HESTIA_USER}" mkdir -p "${WEB_DIR}"
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

  sudo -u "${HESTIA_USER}" wp plugin install ${PLUGINS} --activate --path="${WEB_DIR}"
  sudo -u "${HESTIA_USER}" wp theme install ${THEME} --activate --path="${WEB_DIR}"

  echo "   ✔ ${DOMAIN} installation completed"
  echo "----------------------------------------"
done

echo "Bulk WordPress installation complete!"