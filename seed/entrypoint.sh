#!/usr/bin/env bash
set -euo pipefail

log() { echo "[seed] $*"; }

# --- Wait for Postgres ---
log "Waiting for Postgres..."
until PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql \
  -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" \
  -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -c "select 1" >/dev/null 2>&1; do
  sleep 2
done
log "Postgres is up."

# --- Wait for n8n owner setup ---
log "Waiting for n8n owner setup to complete..."
while true; do
  STATUS=$(PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql \
    -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" \
    -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -t -A -c \
    "select value from settings where key='userManagement.isInstanceOwnerSetUp';" | tr -d '[:space:]')
  [[ "$STATUS" == "true" ]] && { log "Owner setup detected."; break; }
  sleep 3
done

# --- Wait MinIO & ensure bucket ---
log "Waiting for MinIO..."
until curl -sf http://minio:9000/minio/health/live >/dev/null 2>&1; do sleep 2; done
log "MinIO is up."
log "Ensuring MinIO bucket..."
mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
mc mb --ignore-existing "local/$MINIO_BUCKET" || true
log "Bucket ensured: $MINIO_BUCKET"

# --- Resolve n8n owner id ---
OWNER_ID=$(PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql \
  -h "$DB_POSTGRESDB_HOST" -p "$DB_POSTGRESDB_PORT" \
  -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -t -A -c \
  "select id from \"user\" where email='${N8N_OWNER_EMAIL}' limit 1;" | tr -d '[:space:]')
[[ -z "${OWNER_ID}" ]] && { echo "[seed] ERROR: owner not found: ${N8N_OWNER_EMAIL}" >&2; exit 1; }

# --- Render templates with envsubst ---
render_dir() {
  local src_dir="$1"; local dst_dir="$2"
  mkdir -p "$dst_dir"
  shopt -s nullglob

  # Whitelist: only substitute our own env vars; leave $json/$node/$now untouched
  local ALLOWED_VARS
  ALLOWED_VARS=$(env | awk -F= '/^(GDRIVE_|GOOGLE_OAUTH_|POSTGRES_|MINIO_|N8N_|S3_)/ {printf " ${%s}", $1}')

  for tmpl in "$src_dir"/*.tmpl; do
    local base="$(basename "$tmpl" .tmpl)"
    envsubst "$ALLOWED_VARS" < "$tmpl" > "$dst_dir/$base"
    log "Rendered: $base"
  done
}


CRED_TEMPLATES="/seed/credentials-templates"
WF_TEMPLATES="/seed/workflows-templates"
RENDERED_CREDS="/tmp/rendered/credentials"
RENDERED_WF="/tmp/rendered/workflows"


# Load private key from file if defined
if [[ -n "${GDRIVE_PRIVATE_KEY_FILE:-}" && -f "$GDRIVE_PRIVATE_KEY_FILE" ]]; then
  export GDRIVE_PRIVATE_KEY="$(cat "$GDRIVE_PRIVATE_KEY_FILE")"
  echo "[seed] Loaded GDRIVE_PRIVATE_KEY from $GDRIVE_PRIVATE_KEY_FILE"
fi

log "Rendering credentials from env..."
render_dir "$CRED_TEMPLATES" "$RENDERED_CREDS"

log "Rendering workflows from env..."
render_dir "$WF_TEMPLATES" "$RENDERED_WF"

# --- Import rendered credentials & workflows ---
log "Importing credentials..."
n8n import:credentials --input "$RENDERED_CREDS" --separate --userId "$OWNER_ID" || true

log "Importing workflows..."
n8n import:workflow --input "$RENDERED_WF" --separate || true

log "✅ Done."
