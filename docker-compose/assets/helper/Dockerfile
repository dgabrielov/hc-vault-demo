FROM alpine:3.14

# This is the release of Vault to pull in.
ARG VAULT_VERSION=1.9.3

RUN apk add --no-cache su-exec dumb-init jq bash openssl postgresql-client sshpass openssh && \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        armhf) ARCH='arm' ;; \
        aarch64) ARCH='arm64' ;; \
        x86_64) ARCH='amd64' ;; \
        x86) ARCH='386' ;; \
        *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    unzip -d /tmp/build vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    cp /tmp/build/vault /bin/vault && \
    cd /tmp && \
    rm -rf /tmp/build

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

COPY run.sh ./
CMD ./run.sh