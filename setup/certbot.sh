#!/bin/bash

# ------------------------------------------------------
# LetsEncrypt TLS (https) Certbot setup and auto-renewal
# ------------------------------------------------------

# Without CF setting the IP (as may be the case if IPv6 only) it can sometimes
# be that the DNS isn't set quickly enough. Probs need to protect against that.

source /foundryssl/variables.sh

# Install augeas
sudo dnf install -y augeas-libs

# Setup and install python env for certbot and then certbot
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Set up autorenew SSL certs
sudo cp /aws-foundry-ssl/setup/certbot/certbot.sh /foundrycron/certbot.sh
sudo cp /aws-foundry-ssl/setup/certbot/certbot.service /etc/systemd/system/certbot.service
sudo cp /aws-foundry-ssl/setup/certbot/certbot_start.timer /etc/systemd/system/certbot_start.timer
sudo cp /aws-foundry-ssl/setup/certbot/certbot_renew.timer /etc/systemd/system/certbot_renew.timer

# Not sure what this does?
sudo sed -i -e "s|location / {|include conf.d/drop;\n\n\tlocation / {|g" /etc/nginx/conf.d/foundryvtt.conf
sudo cp /aws-foundry-ssl/setup/nginx/drop /etc/nginx/conf.d/drop

# Configure Foundry to use SSL
sudo sed -i 's/"proxyPort":.*/"proxyPort": "443",/g' /foundrydata/Config/options.json
sudo sed -i 's/"proxySSL":.*/"proxySSL": true,/g' /foundrydata/Config/options.json

# Kick off certbot
sudo touch /var/log/foundrycron/certbot_renew.log

# Run the script in another process
sudo systemctl daemon-reload
sudo systemctl enable --now certbot_start.timer
sudo systemctl enable --now certbot_renew.timer
