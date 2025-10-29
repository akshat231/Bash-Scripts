#!/bin/bash

set -e  # Exit on any error
set -u  # Treat unset variables as errors

CURRENT_DIR=$(pwd)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
}

log INFO "Stopping services..."

# --- Stop Cold Email Backend ---
cd "${CURRENT_DIR}/../cold-email/cold-email-backend"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping cold-email-backend containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "cold-email-backend docker-compose.yml not found. Skipping."
fi

# --- Stop Postgres ---
cd "${CURRENT_DIR}/../binaries/postgres"
if [ -f docker-compose.yml ]; then
  log INFO "Stopping Postgres containers..."
  sudo docker-compose -f docker-compose.yml down
else
  log WARN "Postgres docker-compose.yml not found. Skipping."
fi


log INFO "All services stopped and cleaned up successfully."
