#!/bin/bash
source /foundryssl/variables.sh

# NOTE: This script doesn't take into account if the hosting is behind CloudFront (*.cloudfront.net) and won't work if that's the case

updateRecordset () {
    # $1 - Descriptor for logging - "IPv4" or "IPv6"
    # $2 - (sub)domain eg. "mydomain.com"
    # $3 - EC2 IP
    # $4 - RecordSet Type - "A" for IPv4, "AAAA" for IPv6
    # $5 - RecordSet Blob from AWS Resource Record Sets for the domain
    if [[ "$3" != "" ]]; then
        recordset_ip=`echo $5 | jq "select(.Type==\"$4\") | .ResourceRecords[] | .Value" | cut -d '"' -f2`

        # Check IPv4 match
        echo "EC2 $1 Address: $3"
        echo "RRS $1 Address: $recordset_ip"

        if [[ "$3" != "$recordset_ip" ]]; then
            echo "Requesting change for $2 $1 to $3"
            aws route53 change-resource-record-sets --hosted-zone-id ${zone_id} --change-batch "{ \"Comment\": \"Dynamic DNS change\", \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"$2.\", \"Type\": \"$4\", \"TTL\": 120, \"ResourceRecords\": [ { \"Value\": \"$3\" } ] } } ] }"
        else
            echo "$1 matches, no change needed."
        fi
    else
        echo "No local $1 address set; skipping..."
    fi

    echo "-----"
}

# Attempt to retrieve public IPv4 and IPv6 (can use +tries=x +time=y if the timeout is too long)
echo "Querying public IP addresses for the EC2..."
ec2_ipv4_raw="$(dig -4 +short txt ch whoami.cloudflare @1.0.0.1 2>/dev/null | tr -d '"')"
ec2_ipv6_raw="$(dig -6 +short txt ch whoami.cloudflare @2606:4700:4700::1001 2>/dev/null | tr -d '"')"

# Validate IPv4 - must match x.x.x.x pattern
if [[ "$ec2_ipv4_raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ec2_ipv4="$ec2_ipv4_raw"
else
    echo "Warning: Failed to retrieve valid IPv4 address (got: $ec2_ipv4_raw)"
    ec2_ipv4=""
fi

# Validate IPv6 - must contain colons and hex characters only
if [[ "$ec2_ipv6_raw" =~ ^[0-9a-fA-F:]+$ ]]; then
    ec2_ipv6="$ec2_ipv6_raw"
else
    echo "Warning: Failed to retrieve valid IPv6 address (got: $ec2_ipv6_raw)"
    ec2_ipv6=""
fi

# Get IP for subdomain record
recordset_subdomain=`aws route53 list-resource-record-sets --hosted-zone-id ${zone_id} | jq ".ResourceRecordSets[] | select(.Name==\"${subdomain}.${fqdn}.\")"`

# --- Subdomain checks ---
updateRecordset "IPv4" "${subdomain}.${fqdn}" "$ec2_ipv4" "A" "$recordset_subdomain"
updateRecordset "IPv6" "${subdomain}.${fqdn}" "$ec2_ipv6" "AAAA" "$recordset_subdomain"

# --- Optional domain checks ---
if [[ "${webserver_bool}" == "True" ]]; then
    # Get IP for domain record
    recordset_fqdn=`aws route53 list-resource-record-sets --hosted-zone-id ${zone_id} | jq ".ResourceRecordSets[] | select(.Name==\"${fqdn}.\")"`

    updateRecordset "IPv4" "${fqdn}" "$ec2_ipv4" "A" "$recordset_fqdn"
    updateRecordset "IPv6" "${fqdn}" "$ec2_ipv6" "AAAA" "$recordset_fqdn"
fi

echo "--- All done!"