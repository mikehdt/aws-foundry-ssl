#!/bin/bash

# ----------------------------------------------------
# Set up Amazon Linux kernel autopatching for security
# ----------------------------------------------------

# https://docs.aws.amazon.com/linux/al2023/ug/live-patching.html

sudo dnf install -y kpatch-dnf
sudo dnf kernel-livepatch -y auto

sudo dnf install -y kpatch-runtime
sudo dnf update kpatch-runtime

sudo systemctl enable --now kpatch.service
