#!/bin/bash
# bash /home/linksnova007/tmp/wp-cleanup.sh

HESTIA_USER="linksnova007"
DOMAINS=(
    samedayhomecleaning.co.uk
    samedayhousecleaning.co.uk
    scaffolding-company.uk
    scaffoldinghire.org.uk
    scaffolding-hire.uk
    securityguardservices.uk
    shedassembly.co.uk
    shedbuilders.uk
    sheddemolition.co.uk
    sheddismantling.co.uk
    sheddisposal.org.uk
    shed-removal.co.uk
    shedremovals.uk
    shedremoval.uk
    shelfinstallation.co.uk
    shelfmounting.co.uk
    shelveinstallation.co.uk
    shelvinginstallation.co.uk
    shelvinginstallation.uk
    shop-front-spraying.uk
    showermouldremoval.co.uk
    showerresealing.co.uk
    signwriting.org.uk
    siliconeresealing.co.uk
    sitecleaning.co.uk
    skirtingboardfitting.co.uk
    smokealarminstaller.co.uk
    snaggingcompany.org.uk
    sofaremoval.uk
    softstripoutdemolition.uk
    soft-washing.uk
    soilremoval.co.uk
    solar-panel-cleaning.uk
    sound-proofers.co.uk
    sportshallcleaning.co.uk
    stonecleaning.org.uk
    structural-survey.co.uk
    suicidecleanup.co.uk
    summer-houses.co.uk
    summer-houses.uk
    tapeandjointer.uk
    thatchedroofing.org.uk
    thermalimaging.org.uk
    thermostatinstallation.co.uk
    tidyingservice.co.uk
    tilefitting.co.uk
    timber-windows.org.uk
)

SLEEP_EVERY=3
SLEEP_TIME=5
COUNT=0

for DOMAIN in "${DOMAINS[@]}"; do
    ((COUNT++))
    WEB_DIR="/home/${HESTIA_USER}/web/${DOMAIN}/public_html"
    BACKUP_DIR="${WEB_DIR}/wp-content/ai1wm-backups"
    HELLO_FILE="${WEB_DIR}/wp-content/plugins/hello.php"
    
    echo "➤ [$COUNT/${#DOMAINS[@]}] Processing domain: ${DOMAIN}"

    # Cleanup backups
    echo "Removing backup files..."
    sudo -u "${HESTIA_USER}" rm -f "${BACKUP_DIR}/"*.wpress 2>/dev/null

    # Remove themes
    echo "Deleting themes..."
    sudo -u "${HESTIA_USER}" wp theme delete twentytwentyfive twentytwentyfour twentytwentythree --path="${WEB_DIR}"

    # Remove plugins safely
    echo "Deleting plugins..."
    sudo -u "${HESTIA_USER}" wp plugin delete akismet all-in-one-wp-migration hello-dolly --path="${WEB_DIR}"

    # Force remove Hello Dolly if needed
    if [ -f "${HELLO_FILE}" ]; then
        echo "Removing orphaned hello.php..."
        sudo -u "${HESTIA_USER}" rm -f "${HELLO_FILE}"
    fi

    echo "✔ Cleanup completed for ${DOMAIN}"
    echo "----------------------------------------"

    if (( COUNT % SLEEP_EVERY == 0 )); then
        echo "💤 Sleeping for $SLEEP_TIME seconds..."
        sleep $SLEEP_TIME
    fi
done

echo "✅ All domains processed!"
