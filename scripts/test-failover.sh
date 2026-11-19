#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

echo "=== MongoDB Automated HA Failover Test ==="

# Find the current primary using any reachable member.
find_primary() {
  local service result

  for service in mongo1 mongo2 mongo3; do
    result=$(docker compose exec -T "$service" \
      mongosh --quiet --eval \
      'try { print(db.hello().primary || "") } catch(e) {}' \
      2>/dev/null) || continue

    case "$result" in
      mongo1:27017|mongo2:27017|mongo3:27017)
        echo "$result"
        return 0
        ;;
    esac
  done

  return 1
}

ORIGINAL_PRIMARY=$(find_primary) || {
  echo "ERROR: No primary detected"
  exit 1
}

SERVICE="${ORIGINAL_PRIMARY%%:*}"

echo "Original primary: $ORIGINAL_PRIMARY"

# Always attempt recovery of the stopped member.
cleanup() {
  echo "Ensuring $SERVICE is running..."
  docker compose start "$SERVICE" || true
}
trap cleanup EXIT

START=$(date +%s%3N)

echo "Stopping $SERVICE..."
docker compose stop -t 1 "$SERVICE"

echo "Waiting for a new primary..."

NEW_PRIMARY=""

for i in $(seq 1 60); do
  CANDIDATE=$(find_primary || true)

  if [[ -n "$CANDIDATE" &&
        "$CANDIDATE" != "$ORIGINAL_PRIMARY" ]]; then
    NEW_PRIMARY="$CANDIDATE"
    break
  fi

  sleep 1
done

END=$(date +%s%3N)

if [[ -z "$NEW_PRIMARY" ]]; then
  echo "FAIL: No new primary elected within polling window"
  exit 1
fi

echo "New primary: $NEW_PRIMARY"
echo "Observed failover interval: $((END - START)) ms"

NEW_SERVICE="${NEW_PRIMARY%%:*}"

echo "=== Transaction Validation ==="

docker compose exec -T "$NEW_SERVICE" mongosh --quiet --eval '
const d = db.getSiblingDB("banking");
const txn = d.transactions.findOne({transaction_id:"TXN1001"});

if (!txn || txn.status !== "SUCCESS") {
  print("FAIL: TXN1001 missing");
  quit(1);
}

print("TXN1001: SUCCESS");
print("HA FAILOVER TEST: PASSED");
'
