# MongoDB HA & DR — Test Evidence

## Environment
- MongoDB: 8.0
- Deployment: Docker Compose on WSL
- Replica set: rs0
- Members: mongo1, mongo2, mongo3
- Voting majority: 2 of 3

## High Availability Test
- Original primary: mongo1
- Failure simulation: docker compose stop mongo1
- Elected primary: mongo2
- Previous transaction TXN1001: Verified
- Post-failover majority write TXN1002: Successful
- Recovered node: mongo1
- Final topology: 1 PRIMARY, 2 SECONDARY
- Both transactions verified after recovery

## Backup and Restore Test
- Database: banking
- Backup tool: mongodump
- Restore tool: mongorestore
- Format: gzip-compressed archive
- Archive size: 488 bytes
- Backup validation: gzip integrity passed
- Restore target: isolated MongoDB container
- Documents restored: 2
- Restore failures: 0
- Data validation: TXN1001 and TXN1002 verified

## Measurement Limitations
- The 1-second primary detection was measured after container
  shutdown completed; it is not actual failover duration.
- No end-to-end RTO has been measured yet.
- No actual RPO has been measured yet.
- Logical backup restore is not point-in-time recovery.
- All replica-set members share one WSL host.
- This is a local educational lab, not a production deployment.
