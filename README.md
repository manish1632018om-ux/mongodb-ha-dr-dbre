# MongoDB High Availability & Disaster Recovery

A hands-on MongoDB Database Reliability Engineering
(DBRE) portfolio project.

## Overview

This project demonstrates MongoDB replica-set high
availability, automatic primary failover, majority
write durability, backup automation, and isolated
disaster recovery testing.

## Technology Stack

- MongoDB 8.0
- Docker and Docker Compose
- Ubuntu WSL
- Bash scripting
- mongodump and mongorestore
- GitHub Actions

## Architecture

Three-node MongoDB replica set (rs0):

- mongo1:27017 - priority 2
- mongo2:27017 - priority 1
- mongo3:27017 - priority 1

All three nodes are voting, data-bearing members.

Docker host ports:
- mongo1: 27217
- mongo2: 27218
- mongo3: 27219

All host ports are bound to localhost.

## High Availability Testing

Completed tests:

1. Initialized a three-node replica set.
2. Verified primary and secondary membership.
3. Inserted data using majority write concern.
4. Verified replication across all members.
5. Simulated primary failure.
6. Observed automatic primary election.
7. Verified transaction survival.
8. Successfully wrote data after failover.
9. Recovered the failed node.
10. Verified synchronization after recovery.

Automated failover observation: 5.37 seconds.

This interval includes Docker shutdown and polling
overhead and is not application-level outage time.

## Backup and Disaster Recovery

Implemented:

- Timestamped MongoDB logical backups
- Automatic primary discovery
- Compressed archive generation
- gzip integrity validation
- Isolated database restoration
- Automated transaction validation

Observed lab measurements:

- Automated backup: 884 ms
- Automated restore command: 588 ms
- Restored documents: 2
- Restore failures: 0

These measurements are for a very small test dataset.
They are not production RTO benchmarks.

## Scripts

scripts/backup.sh
  Creates and validates a logical backup.

scripts/restore.sh
  Restores an archive into an isolated test database.

scripts/test-failover.sh
  Stops the primary, detects a new primary, validates
  transaction survival, and restarts the stopped node.

## Running the Lab

Requirements:
- Docker Engine
- Docker Compose
- Bash

Start and initialize the MongoDB replica set:

    ./scripts/init-replica-set.sh

The script starts all three MongoDB containers
and initializes rs0 when necessary.

On an already initialized replica set, it checks
the existing configuration without reinitializing it.

The current scripts assume an initialized replica set
and existing sample transactions.

Run automated backup:

    ./scripts/backup.sh

Run automated failover testing:

    ./scripts/test-failover.sh

The restore script requires the separate lab container
named mongodb-dr-restore and a backup archive path.

## CI Validation

GitHub Actions checks:

- Docker Compose configuration
- Bash script syntax
- Required project files

This workflow performs static validation only.
It does not execute MongoDB integration tests.

## Security and Limitations

This is a local educational environment.

- MongoDB authentication is not enabled.
- Containers communicate on a local Docker network.
- Published database ports are localhost-bound.
- Replica-set members share one WSL host.
- Backups are stored locally.
- Logical backups do not provide PITR.
- Cross-region recovery is not implemented.
- No production RPO or RTO has been established.

Production deployments require authentication,
TLS, appropriate network isolation, encrypted
off-host backups, retention policies, monitoring,
and regularly tested recovery procedures.

## Test Evidence

See docs/dr-test-results.md.

## Purpose

Demonstrate practical MongoDB DBA, DBRE, and
reliability engineering skills through reproducible
failure and recovery experiments.
