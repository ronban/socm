#!/bin/sh

export AZURE_CLIENT_ID=$(cat /run/config/socm_app_id)
export AZURE_TENANT_ID=$(cat /run/config/azure_tenant_id)
export AZURE_CLIENT_SECRET=$(cat /run/secrets/socm_app_secret)
export AZURE_VAULT=$(cat /run/config/socm_azkv_name)
export AZURE_ROOTKEY=$(cat /run/config/socm_azkv_rootkey)

az_jwt=$(curl --location --request POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
    --user ${AZURE_CLIENT_ID}:${AZURE_CLIENT_SECRET} \
    --form 'grant_type="client_credentials"' \
    --form 'scope="https://vault.azure.net/.default"')
az_token=$(echo $az_jwt| jq -r ".access_token")

root_token_secret=$(curl --location --request GET "https://${AZURE_VAULT}.vault.azure.net/secrets/${AZURE_ROOTKEY}?api-version=7.3" \
    --header "Authorization: Bearer ${az_token}" \
    --header "Content-Type: application/json")
root_token=$(echo $root_token_secret| jq -r ".value")

vault login $root_token > /dev/null

vault write pki_int/roles/client_certs \
    allow_any_name=true \
    enforce_hostnames=false \
    allow_wildcard_certificates=false \
    client_flag=true \
    server_flag=false \
    no_store=true \
    ou="${VAULT_OU}" \
    organization="${VAULT_ORG_NAME}" \
    country="US" \
    max_ttl="${VAULT_CLIENT_CERT_TTL}"