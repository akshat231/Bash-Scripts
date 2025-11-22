#!/bin/bash

set -e  # Exit on any error
set -u  # Treat unset variables as errors

CURRENT_DIR=$(pwd)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
}

log INFO "Stopping services..."

# --- Stop Scholar Snap AI ---
cd "${CURRENT_DIR}/../../scholar-snap/scholar_snap_ai"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping Scholar-Snap-AI containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "scholar-snap-ai docker-compose.yml not found. Skipping."
fi

# --- Stop Scholar Snap Backend ---
cd "${CURRENT_DIR}/../../scholar-snap/scholar_snap_backend"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping Scholar-Snap-BAckend containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "scholar-snap-backend docker-compose.yml not found. Skipping."
fi

# --- Stop Kafka ---
cd "${CURRENT_DIR}/../../binaries/kafka"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping Kafka containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "Kafka docker-compose.yml not found. Skipping."
fi


# --- Stop Postgres ---
cd "${CURRENT_DIR}/../../binaries/postgres"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping Postgres containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "KPostgres docker-compose.yml not found. Skipping."
fi


log INFO "All services stopped and cleaned up successfully."
