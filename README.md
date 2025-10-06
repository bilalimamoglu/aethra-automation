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
