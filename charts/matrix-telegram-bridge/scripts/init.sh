#!/usr/bin/env sh
set -e

if [ ! -f /data/config.yaml ]; then
    echo "Generating /data/config.yaml file"
    timeout 3s /opt/mautrix-telegram/docker-run.sh
fi

# Apply overrides
if [ -f /opt/config-overrides/overrides.yaml ]; then
    # Remove pre-set permissions
    yq -i e '.bridge.permissions |= {}' /data/config.yaml

    echo "Applying overrides to /data/config.yaml file"
    yq -i e '. *= load("/opt/config-overrides/overrides.yaml")' /data/config.yaml
fi


if [ ! -f /data/registration.yaml ]; then
    timeout 3s /opt/mautrix-telegram/docker-run.sh
fi

echo "All files have been generated!"
