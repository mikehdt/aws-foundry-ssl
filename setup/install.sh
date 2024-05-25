#!/bin/bash

# These files are created in the CloudFormation script
source /foundryssl/variables.sh
source /foundryssl/variables_tmp.sh

# Set up logging to the logfile
exec >> /tmp/foundry-setup.log 2>&1
set -x

# Install foundry
echo "===== 1. INSTALLING DEPENDENCIES ====="
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs
sudo dnf install -y openssl-devel
sudo dnf install -y amazon-cloudwatch-agent

# Install foundry
echo "===== 2. INSTALLING FOUNDRY ====="
source /aws-foundry-ssl/setup/foundry.sh

# Install nginx
echo "===== 3. INSTALLING NGINX ====="
source /aws-foundry-ssl/setup/nginx.sh

# Amazon Cloudwatch logs, zone updates and kernel patching
echo "===== 4. INSTALLING AWS SERVICES AND LINUX KERNEL PATCHING ====="
source /aws-foundry-ssl/setup/aws_cloudwatch_config.sh
source /aws-foundry-ssl/setup/aws_linux_updates.sh

# Set up DNS information
echo "===== 5. CONFIGURING DNS SETTINGS ====="
case ${domain_registrar} in
    amazon)
        sleep 20s	# idk why this is here, but sure
        source /aws-foundry-ssl/setup/aws_hosted_zone_ip.sh
        ;;
    namecheap)
        source /aws-foundry-ssl/setup/namecheap/record_set.sh
        ;;
esac

# Set up TLS certificates with LetsEncrypt
echo "===== 6. INSTALLING LETSENCRYPT CERTBOT ====="
source /aws-foundry-ssl/setup/certbot.sh

# Restart Foundry so aws-s3.json is fully loaded
echo "===== 7. RESTARTING FOUNDRY ====="
sudo systemctl restart foundry

# Clean up install files (Comment out during testing)
echo "===== 8. CLEANUP AND USER PERMISSIONS ====="
sudo usermod -a -G foundry ec2-user
sudo chown ec2-user -R /aws-foundry-ssl

sudo chmod 744 /aws-foundry-ssl/utils/*.sh
sudo chmod 700 /tmp/foundry-setup.log
#sudo rm /foundryssl/variables_tmp.sh

# Uncomment only if you really care to:
# sudo rm -r /aws-foundry-ssl

echo "===== 8. DONE ====="
echo "Finished setting up Foundry!"
