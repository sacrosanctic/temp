#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

git pull

BUILD_VERSION=$(git rev-parse HEAD)
export BUILD_VERSION

echo "$(date --utc +%FT%TZ): Releasing new server@$BUILD_VERSION..."

docker compose rm -f server
docker compose build

OLD_CONTAINER=$(docker compose ps -q server)
echo "$(date --utc +%FT%TZ): Scaling server up..."
docker compose up -d --no-deps --scale server=2 --no-recreate server

NEW_CONTAINER=$(comm -13 <(printf '%s\n' "$OLD_CONTAINER" | sort) <(docker compose ps -q server | sort) | head -1)
echo "$(date --utc +%FT%TZ): Waiting for new server to be healthy..."
HEALTHY=0
for _ in $(seq 1 60); do
  if [ "$(docker inspect -f '{{.State.Health.Status}}' "$NEW_CONTAINER" 2>/dev/null)" = "healthy" ]; then
    HEALTHY=1
    break
  fi
  sleep 1
done

if [ "$HEALTHY" = "0" ]; then
  echo "$(date --utc +%FT%TZ): New server failed health check, rolling back..."
  if [ -n "$NEW_CONTAINER" ]; then
    docker container rm -f "$NEW_CONTAINER"
  fi
  docker compose up -d --no-deps --scale server=1 --no-recreate server
  exit 1
fi

echo "$(date --utc +%FT%TZ): Scaling old server down..."

# Unquoted on purpose: multiple old container IDs must word-split into separate rm args.
# shellcheck disable=SC2086
docker container rm -f $OLD_CONTAINER
docker compose up -d --no-deps --scale server=1 --no-recreate server

echo "$(date --utc +%FT%TZ): Reloading caddy..."
CADDY_CONTAINER=$(docker compose ps -q caddy | head -1)
docker exec "$CADDY_CONTAINER" caddy reload -c /etc/caddy/Caddyfile

echo "$(date --utc +%FT%TZ): Pruning dangling images..."
docker image prune -f
