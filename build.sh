#!/bin/bash
ENV=$1
docker build -t socm-odata_proxy:${ENV} src/odata-proxy
docker build -t socm-vault:${ENV} src/vault
docker build -t socm-logger:${ENV} src/fluentd