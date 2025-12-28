#!/bin/bash

# -------------------------------------------------------
# Enable, disable, or install Amazon Linux kernel updates
#--------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (sudo ./kernel_updates.sh)"
    exit 1
fi

# Default variable values
mode=""

# Function to display script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -h, --help      Display this help message"
    echo " -e, --enable    Enable kernel auto-patching"
    echo " -d, --disable   Disable kernel auto-patching"
    echo " -n, --now       Install available kernel and security patches"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
    echo "${2:-${1#*=}}"
}

handle_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
            -e | --enable)
                mode="enable"
                ;;
            -d | --disable)
                mode="disable"
                ;;
            -n | --now)
                mode="now"
                ;;
            *)
                echo "Invalid option: $1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# Main script execution
handle_options "$@"

if [[ $mode == "" ]]; then
    echo "No options were passed"
    usage
    exit 1
fi

service_running=$(systemctl is-active kpatch.service)

if [[ $mode == "enable" ]]; then
    if [[ $service_running == "active" ]]; then
        echo "Kernel patching service is already enabled!"
        exit 0
    fi

    dnf install -y kpatch-dnf
    dnf kernel-livepatch -y auto

    dnf install -y kpatch-runtime
    dnf update kpatch-runtime

    systemctl enable --now kpatch.service

    echo "Kernel patching service enabled."
    exit 0
fi

if [[ $mode == "disable" ]]; then
    if [[ $service_running != "active" ]]; then
        echo "Kernel patching service is not enabled!"
        exit 0
    fi

    dnf kernel-livepatch manual
    systemctl disable --now kpatch.service

    dnf remove -y kpatch-dnf
    dnf remove -y kpatch-runtime
    dnf remove -y kernel-livepatch

    echo "Kernel patching service disabled."
    exit 0
fi

if [[ $mode == "now" ]]; then
    dnf update --security

    echo "Available security updates applied."
    exit 0
fi

# Should never get here, unless I stuffed something up
echo "Unknown mode ${mode}!"
exit 1
