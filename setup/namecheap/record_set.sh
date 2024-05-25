#!/bin/bash

source /foundryssl/variables.sh
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo dnf install -y ddclient

base_dir="/aws-foundry-ssl/setup/namecheap"

if [[ ${webserver_bool} == "True" ]]
then
    client_conf="${base_dir}/ddclient_webserver.conf"
else
    client_conf="${base_dir}/ddclient.conf"
fi

sudo sed -i "s/api_secret/${api_secret}/g" ${client_conf}
sudo sed -i "s/subdomain/${subdomain}/g" ${client_conf}
sudo sed -i "s/fqdn/${fqdn}/g" ${client_conf}

sudo cat ${client_conf} >> /etc/ddclient.conf

sudo systemctl start ddclient
sudo systemctl enable ddclient

sudo ddclient --force
