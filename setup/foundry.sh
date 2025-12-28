#!/bin/bash

# -------------------------------
# Download and install FoundryVTT
# -------------------------------

mkdir -p /foundrycron /home/foundry/foundry-install /foundrydata /foundrydata/Data /foundrydata/Config

# Download Foundry from Patreon link or Google Drive
cd /home/foundry/foundry-install

rough_filesize=100000000

if [[ `echo ${foundry_download_link} | cut -d '/' -f3` == 'drive.google.com' ]]; then
    # Google Drive link
    echo ">>> Downloading Foundry from a Google Drive link"

    file_id=`echo ${foundry_download_link} | cut -d '/' -f6`
    fs_retry=0

    while (( $fs_retry < 4 )); do
        echo "Attempt $fs_retry..."

        wget --quiet --save-cookies cookies.txt --keep-session-cookies --no-check-certificate "https://drive.usercontent.google.com/download?export=download&id=${file_id}" -O- | sed -rn 's/.*input type="hidden" name="uuid" value="([0-9A-Za-z-]+)".*/\1\n/p' > uuid.txt
        wget --load-cookies cookies.txt -O foundry.zip 'https://drive.usercontent.google.com/download?export=download&id='${file_id}'&authuser=0&confirm=t&uuid='$(<uuid.txt)
        rm -rf cookies.txt uuid.txt

        filesize=$(stat -c%s "./foundry.zip")

        echo "File size of foundry.zip is ${filesize} bytes."

        # Check if the file looks like it downloaded correctly (not a 404 page etc.)
        if (( $filesize > $rough_filesize )); then
            echo "File size seems about right! Proceeding..."
            break
        else
            echo "File size looking too small. Retrying..."
            (( fs_retry++ ))
        fi
    done
else
    # Foundry Patreon or other hosted link
    echo ">>> Downloading Foundry from a Patreon or custom link"

    fs_retry=0

    while (( $fs_retry < 4 )); do
        echo "Attempt $fs_retry..."

        wget -O foundry.zip "${foundry_download_link}"

        filesize=$(stat -c%s "./foundry.zip")

        echo "File size of foundry.zip is ${filesize} bytes."

        # Check if the file looks like it downloaded correctly (not a 404 page etc.)
        if (( $filesize > $rough_filesize )); then
            echo "File size seems about right! Proceeding..."
            break
        else
            echo "File size looking too small. Retrying..."
            (( fs_retry++ ))
        fi
    done
fi

# Final valid size check
if (( $filesize < $rough_filesize )); then
    echo "Error: Downloaded foundry.zip doesn't seem big enough. Check the zip file and URL were correct."
    exit 1
fi

unzip -u foundry.zip
rm -f foundry.zip

# Try to fix the config not having proper permissions on first run
mkdir /foundrydata/Config
touch /foundrydata/Config/options.json

# Allow rwx in the Data folder only for ec2-user:foundry
chown -R foundry:foundry /home/foundry /foundrydata
find /foundrydata -type d -exec chmod 775 {} +
find /foundrydata -type f -exec chmod 664 {} +

# Start foundry and add to boot
cp /aws-foundry-ssl/setup/foundry/foundry.service /etc/systemd/system/foundry.service
chmod 644 /etc/systemd/system/foundry.service

systemctl daemon-reload
systemctl enable --now foundry

# Configure foundry aws json file
F_DIR='/foundrydata/Config/'
echo "Start time: $(date +%s)"

edit_retry=0
while (( edit_retry < 45 )); do
    if [[ -d $F_DIR ]]; then
        echo "Directory found time: $(date +%s)"
        cp /aws-foundry-ssl/setup/foundry/options.json /foundrydata/Config/options.json
        cp /aws-foundry-ssl/setup/foundry/aws-s3.json /foundrydata/Config/aws-s3.json

        # Disable command tracing while handling secrets
        set +x
        echo "Configuring AWS S3 credentials..."
        sed -i "s|ACCESSKEYIDHERE|${access_key_id}|g" /foundrydata/Config/aws-s3.json
        sed -i "s|SECRETACCESSKEYHERE|${secret_access_key}|g" /foundrydata/Config/aws-s3.json
        sed -i "s|REGIONHERE|${region}|g" /foundrydata/Config/aws-s3.json
        set -x

        sed -i 's|"awsConfig":.*|"awsConfig": "/foundrydata/Config/aws-s3.json",|g' /foundrydata/Config/options.json

        break
    else
        echo "Directory not found time: $(date +%s)"
        (( edit_retry++ ))
        sleep 1s
    fi
done
