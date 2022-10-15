#!/usr/bin/env bash

TMPDIR=$(mktemp -d /tmp/helm-charts.XXXXXXXXXX)
trap 'rm -r -f "$TMPDIR"' EXIT

CHART_ROOT="$(dirname "$0")/.."

LATEST_TAG=$(curl --silent \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${CR_TOKEN}" \
  https://api.github.com/repos/mautrix/telegram/releases/latest | yq '.tag_name')

curl --silent \
  --output "${TMPDIR}/example-config.yaml" \
  "https://raw.githubusercontent.com/mautrix/telegram/${LATEST_TAG}/mautrix_telegram/example-config.yaml"

# Keep only console logging
yq -I4 e -i 'del(.logging.root.handlers[] | select(. == "file"))' "${TMPDIR}/example-config.yaml"
yq -I4 e -i 'del(.logging.handlers.file)' "${TMPDIR}/example-config.yaml"

# Set required config to null
readarray noDefaults < <(yq '.no_defaults[]' ${CHART_ROOT}/bin/config/generator-config.yaml )
for noDefault in "${noDefaults[@]}"; do
    key=$(echo "$noDefault" | yq e '.' -)
    export keyPath=".${key}"

    yq e '. |= eval(env(keyPath)) = null' -i "${TMPDIR}/example-config.yaml"
done

# Remove secrets from config
readarray secrets < <(yq '.secrets[]' ${CHART_ROOT}/bin/config/generator-config.yaml )
for secret in "${secrets[@]}"; do
    key=$(echo "$secret" | yq e '.' -)
    export keyPath=".${key}"

    yq e '. |= del(eval(env(keyPath)))' -i "${TMPDIR}/example-config.yaml"
done

# Add telegram bridge config to `values.yaml`
yq ea 'select(fi==1) as $config 
  | select(fi == 0) | .config = $config ' -i "${CHART_ROOT}/values.yaml" "${TMPDIR}/example-config.yaml" 
