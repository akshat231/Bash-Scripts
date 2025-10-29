#!/bin/bash

set -e  # Exit on any error
set -u  # Treat unset variables as errors

NETWORK_NAME="shared_network"
CURRENT_DIR=$(pwd)

POSTGRES_USER="postgres"
NEW_DB_USER="job-seeker"
NEW_DB_PASS="jobs"
NEW_DB_NAME="jobhunt"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
}

# --- Create or verify Docker network ---
if ! docker network ls --filter name=^"${NETWORK_NAME}$" --format '{{.Name}}' | grep -wq "${NETWORK_NAME}"; then
  log INFO "Docker network '${NETWORK_NAME}' not found. Creating it..."
  docker network create "${NETWORK_NAME}"
else
  log INFO "Docker network '${NETWORK_NAME}' already exists."
fi

# --- Run Postgres ---
cd "${CURRENT_DIR}/../../binaries/postgres"
log INFO "Starting Postgres..."
sudo docker-compose -f docker-compose.yml --compatibility up --build -d

# --- Wait for Postgres to be healthy ---
log INFO "Waiting for Postgres to be ready..."
POSTGRES_CONTAINER=$(sudo docker ps --filter "ancestor=postgres" --format "{{.Names}}" | head -n 1)

if [ -z "$POSTGRES_CONTAINER" ]; then
  log ERROR "Could not find a running Postgres container!"
  exit 1
fi

# Wait until Postgres responds to connections
until sudo docker exec "$POSTGRES_CONTAINER" pg_isready -U "$POSTGRES_USER" > /dev/null 2>&1; do
  sleep 2
  log INFO "Waiting for Postgres to accept connections..."
done
log INFO "Postgres is ready."

# --- Create user if missing ---
log INFO "Ensuring database user '$NEW_DB_USER' exists..."
USER_EXISTS=$(sudo docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${NEW_DB_USER}'")
if [ "$USER_EXISTS" != "1" ]; then
  log INFO "Creating user '$NEW_DB_USER'..."
  sudo docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE ROLE \"${NEW_DB_USER}\" LOGIN PASSWORD '${NEW_DB_PASS}';"
else
  log INFO "User '$NEW_DB_USER' already exists. Skipping creation."
fi

# --- Create database if missing ---
log INFO "Ensuring database '$NEW_DB_NAME' exists..."
DB_EXISTS=$(sudo docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='${NEW_DB_NAME}'")
if [ "$DB_EXISTS" != "1" ]; then
  log INFO "Creating database '$NEW_DB_NAME'..."
  sudo docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE DATABASE \"${NEW_DB_NAME}\" OWNER \"${NEW_DB_USER}\";"
else
  log INFO "Database '$NEW_DB_NAME' already exists. Skipping creation."
fi

log INFO "Database and user setup complete."

# --- Run Cold Email Backend ---
cd "${CURRENT_DIR}/../../cold-email/cold-email-backend"
log INFO "Starting cold-email-backend..."
sudo docker-compose -f docker-compose.yml --compatibility up --build -d

# --- Run Sequelize migrations ---
log INFO "Running Sequelize migrations..."
if ! sudo docker exec cold-mail-backend npx sequelize db:migrate; then
  log ERROR "Database migration failed!"
  exit 1
fi

log INFO "Setup completed successfully."
