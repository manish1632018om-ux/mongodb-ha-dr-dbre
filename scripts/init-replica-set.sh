#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

echo "=== MongoDB Replica Set Initialization ==="

docker compose up -d

echo "Waiting for mongo1 to accept connections..."

READY=false

for i in $(seq 1 30); do
  if docker compose exec -T mongo1 \
    mongosh --quiet --eval \
    'db.adminCommand({ping:1})' >/dev/null 2>&1; then
    READY=true
    break
  fi

  sleep 2
done

if [[ "$READY" != "true" ]]; then
  echo "ERROR: mongo1 is not ready"
  exit 1
fi

echo "Checking replica-set initialization..."

docker compose exec -T mongo1 mongosh --quiet --eval '
let status;

try {
  status = db.adminCommand({replSetGetStatus:1});
} catch (error) {
  status = {ok: 0, code: error.code, errmsg: error.message};
}

if (status.ok === 1) {
  print("Replica set already initialized");
  quit(0);
}

if (status.code !== 94) {
  print("ERROR: Unexpected replica-set status");
  printjson(status);
  quit(1);
}

print("Initializing replica set rs0...");

const result = rs.initiate({
  _id: "rs0",
  members: [
    {_id:0, host:"mongo1:27017", priority:2},
    {_id:1, host:"mongo2:27017", priority:1},
    {_id:2, host:"mongo3:27017", priority:1}
  ]
});

printjson(result);

if (result.ok !== 1) quit(1);
'

echo "Replica-set initialization check completed"
