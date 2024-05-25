#!/bin/bash

# -----------------------
# Install nginx webserver
# -----------------------

if [[ ${webserver_bool} == "True" ]]; then
    foundry_file="foundryvtt_webserver.conf"
else
    foundry_file="foundryvtt.conf"
fi

# Install nginx
sudo dnf install nginx -y

# Configure nginx
sudo mkdir /var/log/nginx/foundry
sudo cp /aws-foundry-ssl/setup/nginx/${foundry_file} /etc/nginx/conf.d/foundryvtt.conf
sudo sed -i "s/YOURSUBDOMAINHERE/${subdomain}/g" /etc/nginx/conf.d/foundryvtt.conf
sudo sed -i "s/YOURDOMAINHERE/${fqdn}/g" /etc/nginx/conf.d/foundryvtt.conf

# Start nginx
sudo systemctl enable --now nginx

# Configure foundry for nginx
sudo sed -i "s/\"hostname\":.*/\"hostname\": \"${subdomain}\.${fqdn}\",/g" /foundrydata/Config/options.json
sudo sed -i 's/"proxyPort":.*/"proxyPort": "80",/g' /foundrydata/Config/options.json

# Setup webserver
if [[ ${webserver_bool} == "True" ]]; then
    # Copy webserver files
    git clone https://github.com/zkkng/foundry-website.git /foundry-website
    sudo cp -rf /foundry-website/* /usr/share/nginx/html

    # Give ec2-user permissions
    sudo chown ec2-user -R /usr/share/nginx/html
    sudo chmod 755 -R /usr/share/nginx/html

    # Clean up install files
    sudo rm -r /foundry-website
fi

systemctl restart nginx
