#!/bin/bash

# ------------------------------------------------
# Foundry VTT Health Check
# Restarts Foundry if it's running but unresponsive
# (Addresses V11+ behaviour where Foundry doesn't
# exit after updates, causing 502 errors)
# ------------------------------------------------

# Check if Foundry service is running
service_status=$(systemctl is-active foundry)

if [[ "$service_status" != "active" ]]; then
    echo "Foundry service is not running, skipping health check."
    exit 0
fi

# Try to reach Foundry on localhost
# Timeout after 10 seconds, follow redirects
http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://127.0.0.1:30000)

if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
    echo "Foundry is healthy (HTTP $http_code)"
    exit 0
fi

# If we get here, Foundry is running but not responding properly
echo "Foundry is unresponsive (HTTP $http_code), restarting..."
systemctl restart foundry

# Wait a moment and check again
sleep 5
http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://127.0.0.1:30000)

if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
    echo "Foundry restarted successfully (HTTP $http_code)"
else
    echo "Warning: Foundry may still be starting up (HTTP $http_code)"
fi
