#!/bin/bash

# ------------------------------------------
# Use after uploading assets to /foundrydata
# ------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (sudo ./fix_folder_permissions.sh)"
    exit 1
fi

echo "Fixing foundry user and group ownership..."
chown -R foundry:foundry /home/foundry/ /foundrydata

echo "Fixing folder permissions within /foundrydata..."
find /foundrydata -type d -exec chmod 775 {} +

echo "Fixing file permission within /foundrydata..."
find /foundrydata -type f -exec chmod 664 {} +

echo "Done! If Foundry doesn't see the new files, run the restart_foundry.sh script."
