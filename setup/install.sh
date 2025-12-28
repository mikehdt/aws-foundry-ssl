#!/bin/bash

# Helper function for timestamped logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Set up logging to the logfile
exec >> /tmp/foundry-setup.log 2>&1

# Source variables - do this BEFORE set -x to avoid logging secrets
# variables_tmp.sh contains sensitive AWS credentials
source /foundryssl/variables.sh
source /foundryssl/variables_tmp.sh

# Now enable command tracing (secrets are already loaded)
set -x

log "===== 1. INSTALLING DEPENDENCIES ====="
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
dnf install -y openssl-devel
dnf install -y amazon-cloudwatch-agent

log "===== 2. INSTALLING FOUNDRY ====="
source /aws-foundry-ssl/setup/foundry.sh

log "===== 3. INSTALLING NGINX ====="
source /aws-foundry-ssl/setup/nginx.sh

log "===== 4. INSTALLING AWS SERVICES AND LINUX KERNEL PATCHING ====="
source /aws-foundry-ssl/setup/aws_cloudwatch_config.sh
source /aws-foundry-ssl/setup/aws_hosted_zone_ip.sh
source /aws-foundry-ssl/setup/aws_linux_updates.sh

log "===== 5. INSTALLING LETSENCRYPT CERTBOT ====="
source /aws-foundry-ssl/setup/certbot.sh

log "===== 6. RESTARTING FOUNDRY ====="
systemctl restart foundry

log "===== 7. CLEANUP AND USER PERMISSIONS ====="
usermod -a -G foundry ec2-user
chown ec2-user -R /aws-foundry-ssl

chmod 744 /aws-foundry-ssl/utils/*.sh
chmod 700 /tmp/foundry-setup.log
rm /foundryssl/variables_tmp.sh

# Uncomment only if you really care to:
# rm -rf /aws-foundry-ssl

log "===== 8. DONE ====="
log "Finished setting up Foundry!"
