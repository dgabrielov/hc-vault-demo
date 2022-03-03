HashiCorp Vault Demo - Docker-Compose Deployment
------------

This directory contains resources for the Vault Demo for `docker-compose`.

Use Cases
------------

This demo showcases the following Vault use cases:

* Multi-Tenancy (Namespaces, Policies)
* Dynamic Database Credentials (PostgreSQL)
* One Time Passwords (SSH)
* Static Secrets (Simple KV)
* Secrets Versioning (KV v2)
* SIEM Integration (Splunk)

Prerequisites
------------

1. Change variables in .env from default values, if desired.

1. Place unzipped Vault App for Splunk under `assets/splunk/vault-app-for-splunk`

1. Place Vault Enterprise license under `vault/config` as vault.hclic.

Usage
------------

There is a helper script called `run` in this directory. You can use this script to build and destroy the deployment. Deployment architectures are available in single instance & clustered (coming soon) configurations.

Start the docker-compose deployment:

```bash
./run build [single|cluster]
```

Destroy:

```bash
./run destroy [single|cluster]
```

Rebuild:

```bash
./run rebuild [single|cluster]
```