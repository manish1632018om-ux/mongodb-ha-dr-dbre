#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

BACKUP_FILE="${1:-}"
RESTORE_CONTAINER="mongodb-dr-restore"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "Usage: $0 <backup-archive>"
  exit 1
fi

if [[ ! -s "$BACKUP_FILE" ]]; then
  echo "ERROR: Backup file missing or empty"
  exit 1
fi

gzip -t "$BACKUP_FILE"

if [[ "$(docker inspect -f '{{.State.Running}}' "$RESTORE_CONTAINER")" != "true" ]]; then
  echo "ERROR: Restore container is not running"
  exit 1
fi

RESTORE_DB="banking_restore_$(date -u +%Y%m%d_%H%M%S)_$$"

echo "=== MongoDB Automated DR Restore ==="
echo "Archive: $BACKUP_FILE"
echo "Destination database: $RESTORE_DB"

START=$(date +%s%3N)

docker exec -i "$RESTORE_CONTAINER" \
  mongorestore \
  --archive \
  --gzip \
  --nsFrom='banking.*' \
  --nsTo="${RESTORE_DB}.*" \
  < "$BACKUP_FILE"

END=$(date +%s%3N)

echo "=== Restore Validation ==="

docker exec "$RESTORE_CONTAINER" mongosh --quiet --eval "
const d = db.getSiblingDB('$RESTORE_DB');
const collection = d.transactions;

const count = collection.countDocuments({});
const txn1 = collection.findOne({transaction_id:'TXN1001'});
const txn2 = collection.findOne({transaction_id:'TXN1002'});

print('Documents restored:', count);
print('TXN1001:', txn1?.status || 'MISSING');
print('TXN1002:', txn2?.status || 'MISSING');

if (count !== 2 ||
    txn1?.status !== 'SUCCESS' ||
    txn2?.status !== 'SUCCESS') {
  print('DR VALIDATION: FAILED');
  quit(1);
}

print('DR VALIDATION: PASSED');
"

echo "Restore command duration: $((END - START)) ms"
echo "Restored database: $RESTORE_DB"
