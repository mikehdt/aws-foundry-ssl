#!/bin/bash

# ----------------------------------------------------
# Set up Amazon Linux kernel autopatching for security
# ----------------------------------------------------

# https://docs.aws.amazon.com/linux/al2023/ug/live-patching.html

#sudo yum install -y kpatch-dnf
sudo yum kernel-livepatch -y auto

sudo yum install -y kpatch-runtime
sudo yum update kpatch-runtime

sudo systemctl enable --now kpatch.service
