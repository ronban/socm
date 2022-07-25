#!/bin/sh
sleep 10

export AZURE_CLIENT_ID=$(cat /run/config/socm_app_id)
export AZURE_TENANT_ID=$(cat /run/config/azure_tenant_id)
export AZURE_CLIENT_SECRET=$(cat /run/secrets/socm_app_secret)
export AZURE_VAULT=$(cat /run/config/socm_azkv_name)
export AZURE_ROOTKEY=$(cat /run/config/socm_azkv_rootkey)
export AZURE_RECKEY=$(cat /run/config/socm_azkv_reckey)
export LOGGER_HOST=$(cat /run/config/socm_logger_host)
export LOGGER_PORT=$(cat /run/config/socm_syslogger2_port)
export USER_KEY=$(cat /run/config/socm_user_key)

inited=$(vault status | jq -r ".initialized")
if [[ ${inited} == 'false' ]]; then
  # Run Intialization commands
  
  echo Setting up with the following values
  echo VAULT_RECOVERY_SHARES $VAULT_RECOVERY_SHARES
  echo VAULT_RECOVERY_THRESHOLD $VAULT_RECOVERY_THRESHOLD
  echo VAULT_ROOTCA_CN $VAULT_ROOTCA_CN
  echo VAULT_SUBCA_CN $VAULT_SUBCA_CN
  echo VAULT_OU $VAULT_OU
  echo VAULT_ORG_NAME $VAULT_ORG_NAME
  echo VAULT_CLIENT_CERT_TTL $VAULT_CLIENT_CERT_TTL

  keys_json=$(vault operator init -recovery-shares=${VAULT_RECOVERY_SHARES} -recovery-threshold=${VAULT_RECOVERY_THRESHOLD})

  root_token=$(echo ${keys_json}| jq -r ".root_token")
  recovery_tokens=$(echo ${keys_json}| jq -r ".recovery_keys_b64")
  recovery_keys_b64=$(echo ${recovery_tokens} | base64 - )

  ## Store keys in azure
  #Get Azure JWT
  az_jwt=$(curl --location --request POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
       --user ${AZURE_CLIENT_ID}:${AZURE_CLIENT_SECRET} \
       --form 'grant_type="client_credentials"' \
       --form 'scope="https://vault.azure.net/.default"')
  az_token=$(echo $az_jwt| jq -r ".access_token")
  curl --location --request PUT "https://${AZURE_VAULT}.vault.azure.net/secrets/${AZURE_ROOTKEY}?api-version=7.2" \
       --header "Authorization: Bearer ${az_token}" \
       --header "Content-Type: application/json" \
       --data-raw "{\"value\": \"${root_token}\"}"
   
  curl --location --request PUT "https://${AZURE_VAULT}.vault.azure.net/secrets/${AZURE_RECKEY}?api-version=7.2" \
       --header "Authorization: Bearer ${az_token}" \
       --header "Content-Type: application/json" \
       --data-raw "{\"value\": \"${recovery_keys_b64}\"}"

  

  # Run CA Setup
    pki_stat=`curl -k -s -o /tmp/http_stat.out -w "%{http_code}" ${VAULT_ADDR}/v1/pki/ca/pem`

  if [[ $pki_stat != '200' ]]; then
      vault login $root_token > /dev/null
      # Configure Logging
      #vault audit enable socket address=${LOGGER_HOST}:${LOGGER_PORT} socket_type=udp format=json prefix=vault
      vault audit enable file file_path=/vault/logs/audit.log

      vault secrets enable pki
      vault secrets tune -max-lease-ttl=87600h pki
      vault write -field=certificate pki/root/generate/internal \
            common_name="${VAULT_ROOTCA_CN}" \
            ou="${VAULT_OU}" \
            organization="${VAULT_ORG_NAME}" \
            country="US" \
            ttl=87600h > /dev/null
      vault write pki/config/urls \
            issuing_certificates="${VAULT_ADDR}/v1/pki/ca" \
            crl_distribution_points="${VAULT_ADDR}/v1/pki/crl"


      #Inter CA Setup
      vault secrets enable -path=pki_int pki
      vault secrets tune -max-lease-ttl=43800h pki_int

      vault write -format=json pki_int/intermediate/generate/internal \
            common_name="${VAULT_SUBCA_CN}" \
            ou="${VAULT_OU}" \
            organization="${VAULT_ORG_NAME}" \
            country="US" \
            | jq -r '.data.csr' > /tmp/pki_intermediate.csr

      vault write -format=json pki/root/sign-intermediate \
                      csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" \
                      |jq -r '.data.certificate' > /tmp/socm-interca.pem


      vault write pki_int/intermediate/set-signed \
                      certificate=@/tmp/socm-interca.pem

      vault write pki_int/config/urls \
            issuing_certificates="${VAULT_ADDR}/v1/pki_int/ca" \
            crl_distribution_points="${VAULT_ADDR}/v1/pki_int/crl"

      #Create a role
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


      #Create Authentication
      AZURE_OIDC_DISCOVERY_URL=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
      AZURE_ISSUER=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
      vault auth enable jwt

      vault write auth/jwt/config \
        oidc_discovery_url="${AZURE_OIDC_DISCOVERY_URL}" \
        bound_issuer="${AZURE_ISSUER}"
        default_role="jwt_client_cert"

      vault write auth/jwt/role/jwt_client_cert \
            role_type="jwt" \
            policies=flask_app_cert_gen_pol \
            bound_audiences="${AZURE_CLIENT_ID}" \
            user_claim="${USER_KEY}" \
            token_no_default_policy=true \
            clock_skew_leeway=0 \
            token_num_uses=1 \
            token_type="service"

      #Create policies     
      echo 'path "pki_int/issue/client_certs" {
            capabilities = ["update"]
      }' | vault policy write flask_app_cert_gen_pol -
      exit
  fi
elif [[ ${inited} == 'true' ]]; then
  sealed=$(vault status | jq -r ".sealed")
  if [[ ${sealed} == 'false' ]]; then
      #all ok, just run the patches
      /usr/local/bin/patch-*.sh
      echo "All OK"
      exit
  else
      #something is wrong
      echo "Not OK"
      exit -1
  fi
fi