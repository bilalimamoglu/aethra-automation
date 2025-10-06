#!/usr/bin/env bash
set -euo pipefail

echo "[debug] Encryption key hash: $(echo $N8N_ENCRYPTION_KEY | sha256sum)"

echo "[seed] Waiting for Postgres..."
until PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql \
  -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" \
  -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -c "select 1" >/dev/null 2>&1; do
  sleep 2
done
echo "[seed] Postgres is up."

echo "[seed] Waiting for n8n owner setup (UI signup) to be completed..."
while true; do
  STATUS=$(PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql \
    -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" \
    -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -t -A -c \
    "select value from settings where key='userManagement.isInstanceOwnerSetUp';" | tr -d '[:space:]')
  if [[ "$STATUS" == "true" ]]; then
    echo "[seed] Owner setup detected. Proceeding."
    break
  fi
  sleep 3
done

echo "[seed] Waiting for MinIO..."
until curl -sf http://minio:9000/minio/health/live >/dev/null 2>&1; do
  sleep 2
done
echo "[seed] MinIO is up."

echo "[seed] Ensuring MinIO bucket..."
mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
mc mb --ignore-existing "local/$MINIO_BUCKET" || true
echo "[seed] Bucket ensured: $MINIO_BUCKET"

# Import credentials (each file is a single credential)
if [ -d /seed/credentials ]; then
  echo "[seed] Importing credentials..."
  n8n import:credentials --input "/seed/credentials" --separate || true
fi

# Import workflows (each file is a single workflow)
if [ -d /seed/workflows ]; then
  echo "[seed] Importing workflows..."
  n8n import:workflow --input "/seed/workflows" --separate || true
fi

echo "[seed] ✅ Done."
