#!/bin/sh

# Gunicorn 'Green Unicorn' is a Python WSGI HTTP Server for UNIX. 
# It's a pre-fork worker model. 
# The Gunicorn server is broadly compatible and simply implemented.
# Its light on server resources, and fairly speedy.

# Here we will be spinning up multiple threads with multiple worker processess(-w) and perform a binding.

export AZURE_JWKSURI=https://login.microsoftonline.com/$(cat /run/config/azure_tenant_id)/discovery/v2.0/keys
export AZURE_ISSUER=https://login.microsoftonline.com/$(cat /run/config/azure_tenant_id)/v2.0
export AZURE_CLIENT_ID=$(cat /run/config/socm_app_id)
export SAP_ENDPOINT=$(cat /run/config/sap_endpoint)
export VAULT_URI=$(cat /run/config/socm_vault_uri)
export LOGGER_HOST=$(cat /run/config/socm_logger_host)
export LOGGER_PORT=$(cat /run/config/socm_logger_port)
export LOG_LEVEL=$(cat /run/config/socm_log_level)
export METADATA_URI=$(cat /run/config/socm_metadata_uri)
export CERT_TEMPLATE=/app/flaskAppServer/cert_template.json.tpl


gunicorn flaskAppServer:"create_app()" -w 2 --threads 2 -b 0.0.0.0:5001