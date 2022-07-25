FROM vault:1.9.3

ENV VAULT_ADDR http://127.0.0.1:8200/
ENV VAULT_FORMAT json

RUN apk update && \
    apk add --no-cache jq && \
    apk add --no-cache curl && \
    apk add --no-cache gettext

RUN mkdir /policies

COPY setup/*.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/setup_init.sh
RUN chmod +x /usr/local/bin/patch-*.sh

COPY vault.hcl /vault/config/vault.hcl
COPY vault.sh  /vault/vault.sh
RUN chmod +x /vault/vault.sh

ENTRYPOINT /vault/vault.sh
