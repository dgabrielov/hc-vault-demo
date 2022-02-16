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

1. Place unzipped Vault App for Splunk under `vault/vault-app-for-splunk`

Usage
------------

Helpful commands:

     docker-compose up -d
     docker-compose down -v --rmi [local, all]
     docker-compose down -v --rmi [local, all] && docker-compose up -d 

MacOS/Docker Desktop Users:

    docker-compose -p=demo-vault-docker up -d 
    docker-compose -p=demo-vault-docker down -v --rmi [local, all]
    docker-compose -p=demo-vault-docker down -v --rmi [local,all] && docker-compose -p=demo-vault-docker up -d 

