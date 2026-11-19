#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

BACKUP_ROOT="$PWD/backups"
mkdir -p "$BACKUP_ROOT"

TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_ROOT/banking-$TIMESTAMP.archive.gz"
TEMP_FILE="${BACKUP_FILE}.partial"

trap 'rm -f "$TEMP_FILE"' EXIT

echo "=== MongoDB Automated Backup ==="

# Discover the current primary through replica-set status.
PRIMARY_HOST=$(docker compose exec -T mongo1 \
  mongosh --quiet --eval \
  'print(rs.status().members.find(m => m.stateStr === "PRIMARY")?.name || "")')

case "$PRIMARY_HOST" in
  mongo1:27017) SERVICE=mongo1 ;;
  mongo2:27017) SERVICE=mongo2 ;;
  mongo3:27017) SERVICE=mongo3 ;;
  *)
    echo "ERROR: No recognized primary found."
    exit 1
    ;;
esac

echo "Primary: $SERVICE"
echo "Backup started: $(date -u)"

START=$(date +%s%3N)

docker compose exec -T "$SERVICE" \
  mongodump \
  --host localhost \
  --port 27017 \
  --db banking \
  --archive \
  --gzip > "$TEMP_FILE"

test -s "$TEMP_FILE"
gzip -t "$TEMP_FILE"

mv "$TEMP_FILE" "$BACKUP_FILE"

END=$(date +%s%3N)

echo "Backup completed successfully"
echo "Backup file: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Duration: $((END - START)) ms"
echo "Integrity: PASS"
