#!/bin/sh

export AZURE_CLIENT_ID=$(cat /run/config/socm_app_id)
export AZURE_TENANT_ID=$(cat /run/config/azure_tenant_id)
export AZURE_CLIENT_SECRET=$(cat /run/secrets/socm_app_secret)
export AZURE_VAULT=$(cat /run/config/socm_azkv_name)
export AZURE_ROOTKEY=$(cat /run/config/socm_azkv_rootkey)
export AZURE_RECKEY=$(cat /run/config/socm_azkv_reckey)
export AZURE_OIDC_DISCOVERY_URL=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
export AZURE_ISSUER=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0

##Update Config
#Get Azure JWT
az_jwt=$(curl --location --request GET "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
--user ${AZURE_CLIENT_ID}:${AZURE_CLIENT_SECRET} \
--form 'grant_type="client_credentials"' \
--form 'scope="https://vault.azure.net/.default"')

az_token=$(echo $az_jwt| jq -r ".access_token")

root_token=$(curl --location --request GET "https://${AZURE_VAULT}.vault.azure.net/secrets/${AZURE_ROOTKEY}?api-version=7.2" \
--header "Authorization: Bearer ${az_token}" \
--header "Content-Type: application/json" \
--data-raw "{\"value\": \"${root_token}\"}")

vault login $root_token > /dev/null
vault write auth/jwt/config \
oidc_discovery_url="${AZURE_OIDC_DISCOVERY_URL}" \
bound_issuer="${AZURE_ISSUER}"
default_role="jwt_client_cert"

vault write auth/jwt/role/jwt_client_cert \
    role_type="jwt" \
    policies=flask_app_cert_gen_pol \
    bound_audiences="${AZURE_CLIENT_ID}" \
    user_claim="upn" \
    token_no_default_policy=true \
    clock_skew_leeway=0 \
    token_num_uses=1 \
    token_type="service"