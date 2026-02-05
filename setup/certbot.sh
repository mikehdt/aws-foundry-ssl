#!/bin/bash

# ------------------------------------------------------
# LetsEncrypt TLS (https) Certbot setup and auto-renewal
# ------------------------------------------------------

# Without CF setting the IP (as may be the case if IPv6 only) it can sometimes
# be that the DNS isn't set quickly enough. Probs need to protect against that.

source /foundryssl/variables.sh

# Install augeas
dnf install -y augeas-libs

# Setup and install python env for certbot and then certbot
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-nginx
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Set up autorenew SSL certs
cp /aws-foundry-ssl/setup/certbot/certbot.sh /foundrycron/certbot.sh
chmod +x /foundrycron/certbot.sh
cp /aws-foundry-ssl/setup/certbot/certbot.service /etc/systemd/system/certbot.service
cp /aws-foundry-ssl/setup/certbot/certbot_start.timer /etc/systemd/system/certbot_start.timer
cp /aws-foundry-ssl/setup/certbot/certbot_renew.timer /etc/systemd/system/certbot_renew.timer

# Not sure what this does?
sed -i -e "s|location / {|include conf.d/drop;\n\n\tlocation / {|g" /etc/nginx/conf.d/foundryvtt.conf
cp /aws-foundry-ssl/setup/nginx/drop /etc/nginx/conf.d/drop

# Configure Foundry to use SSL
sed -i 's/"proxyPort":.*/"proxyPort": "443",/g' /foundrydata/Config/options.json
sed -i 's/"proxySSL":.*/"proxySSL": true,/g' /foundrydata/Config/options.json

# Run the script in another process
systemctl daemon-reload
systemctl enable --now certbot_start.timer
systemctl enable --now certbot_renew.timer
