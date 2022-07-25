#!/bin/sh

export AZURE_CLIENT_ID=$(cat /run/config/socm_app_id)
export AZURE_TENANT_ID=$(cat /run/config/azure_tenant_id)
export AZURE_CLIENT_SECRET=$(cat /run/secrets/socm_app_secret)
export VAULT_AZUREKEYVAULT_VAULT_NAME=$(cat /run/config/socm_azkv_name)
export VAULT_AZUREKEYVAULT_KEY_NAME=$(cat /run/config/socm_azkv_sealkey)
export VAULT_SEAL_TYPE=azurekeyvault

export VAULT_ADDR=http://127.0.0.1:8200/
export VAULT_FORMAT=json

#setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
/usr/local/bin/setup_init.sh &
vault server -config=/vault/config/vault.hcl