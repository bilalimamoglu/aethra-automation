# Aethra Automation (Local Dev)

This repository contains a **n8n + Postgres + MinIO (S3-compatible)** stack for local development.
- Runs with Docker Compose.
- Manage workflows and credentials via the n8n interface.
- MinIO provides local S3 emulation.
- Postgres is used as the n8n database (workflows, credentials, etc. with n8n's own schema).

## Quick Start

1) Copy `.env.example` to `.env` and edit the values  
   ```
    cp .env.example .env
    # Generate a random encryption key (32-byte hex)
    KEY=$(openssl rand -hex 32); sed -i.bak "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$KEY|" .env && rm .env.bak
    ```

2) Run `docker compose up -d`  
3) n8n UI: http://localhost:5678  
   MinIO Console: http://localhost:9001  
4) Define **Credentials** in the n8n UI (Postgres, S3/MinIO)  
5) Optionally, import and test the `00_hello_webhook.json` workflow.


docker compose down -v --remove-orphans  # tüm volume'ları da sil, cache kalmasın
docker compose build --no-cache seed
docker compose up -d postgres minio n8n
docker compose run --rm seed   


~ $ cat /tmp/creds/*.json | jq '.id, .name'
"3f8d0f1a-7a22-4ab6-9f52-6b6b5a1d9a01"
"Aethra Google Drive (Service Account)"
"7b8b5b7e-2f2c-4c77-9f3c-0b7c8a9d1f01"
"Aethra Google Drive (OAuth2)"
"8b6f3c41-5d62-4a9c-9e0e-2f3a6c7d8e90"
"Aethra S3 (MinIO Local)"
"9a8a2f2a-2b7b-4b9e-8d5b-1cf1f6f7e0a1"
"Aethra Postgres (Local)"
~ $