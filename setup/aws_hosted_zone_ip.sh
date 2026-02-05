#!/bin/bash

# ---------------------------------------------------------------
# Set up dynamic DNS and automatic AWS zone ID resolution updates
# ---------------------------------------------------------------

if [[ -z "${fqdn}" ]]; then
    echo "Variable \$fqdn is empty, cannot update AWS without a fully qualified domain name."
    exit 1
fi

zone_id=`aws route53 list-hosted-zones | jq ".HostedZones[] | select(.Name==\"${fqdn}.\") | .Id" | cut -d / -f3 | cut -d '"' -f1`

echo "DNS Zone ID: ${zone_id}"

# If zone_id is set, update it. Otherwise, append it
grep -q "^zone_id=" /foundryssl/variables.sh && sed "s/^zone_id=.*/zone_id=${zone_id}/" -i /foundryssl/variables.sh || sed "$ a\zone_id=${zone_id}" -i /foundryssl/variables.sh

cp /aws-foundry-ssl/setup/aws/hosted_zone_ip.sh /foundrycron/hosted_zone_ip.sh
chmod +x /foundrycron/hosted_zone_ip.sh
cp /aws-foundry-ssl/setup/aws/hosted_zone_ip.service /etc/systemd/system/hosted_zone_ip.service
cp /aws-foundry-ssl/setup/aws/hosted_zone_ip.timer /etc/systemd/system/hosted_zone_ip.timer

# We do run this twice technically... this is so that it's blocking before Certbot can run
source /foundrycron/hosted_zone_ip.sh

# Start the timer and set it up for restart support too
systemctl daemon-reload
systemctl enable --now hosted_zone_ip.timer
