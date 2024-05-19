#!/bin/bash

# -------------------------------
# Download and install FoundryVTT
# -------------------------------

sudo mkdir -p /foundrycron /var/log/foundrycron /home/foundry/foundry-install /foundrydata /foundrydata/Data /foundrydata/Config

# Download Foundry from Patreon link or Google Drive
cd /home/foundry/foundry-install
rm -rf ./* # Just in case we are running this a second time

rough_filesize=100000000

if [[ `echo ${foundry_download_link} | cut -d ':' -f1` == 's3' ]]; then
    aws s3 cp ${foundry_download_link} ./foundry.zip
elif [[ `echo ${foundry_download_link} | cut -d '/' -f3` == 'drive.google.com' ]]; then
    # Google Drive link
    echo ">>> Downloading Foundry from a Google Drive link"

    file_id=`echo ${foundry_download_link} | cut -d '/' -f6`

    while (( fs_retry < 4 )); do
        echo "Attempt $fs_retry..."

        gdown ${file_id} && mv ./* ./foundry.zip
		
        # Check if the file looks like it downloaded correctly (not a 404 page etc.)
        filesize=$(stat -c%s "./foundry.zip")

        echo "File size of foundry.zip is ${filesize} bytes."

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

    while (( fs_retry < 4 )); do
        echo "Attempt $fs_retry..."

        sudo wget -O foundry.zip "${foundry_download_link}"

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

# Allow rwx in the Data folder only for ec2-user:foundry
sudo chown -R foundry:foundry /home/foundry /foundrydata /foundrydata/Config
sudo find /foundrydata -type d -exec chmod 775 {} +
sudo find /foundrydata -type f -exec chmod 664 {} +

# Start foundry and add to boot
sudo cp /aws-foundry-ssl/setup/foundry/foundry.service /etc/systemd/system/foundry.service
sudo chmod 644 /etc/systemd/system/foundry.service

sudo systemctl daemon-reload
sudo systemctl enable --now foundry

# Configure foundry aws json file
F_DIR='/foundrydata/Config/'
echo "Start time: $(date +%s)"

while (( edit_retry < 45 )); do
    if [[ -d $F_DIR ]]; then
        echo "Directory found time: $(date +%s)"
        sudo cp /aws-foundry-ssl/setup/foundry/options.json /foundrydata/Config/options.json
        sudo cp /aws-foundry-ssl/setup/foundry/aws-s3.json /foundrydata/Config/aws-s3.json
        sudo sed -i "s|ACCESSKEYIDHERE|${access_key_id}|g" /foundrydata/Config/aws-s3.json
        sudo sed -i "s|SECRETACCESSKEYHERE|${secret_access_key}|g" /foundrydata/Config/aws-s3.json
        sudo sed -i "s|REGIONHERE|${region}|g" /foundrydata/Config/aws-s3.json
        sudo sed -i 's|"awsConfig":.*|"awsConfig": "/foundrydata/Config/aws-s3.json",|g' /foundrydata/Config/options.json

        break
    else
        echo  echo "Directory not found time: $(date +%s)"
        (( edit_retry++ ))
        sleep 1s
    fi
done
