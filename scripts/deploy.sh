#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

git pull

BUILD_VERSION=$(git rev-parse HEAD)
export BUILD_VERSION

echo "$(date --utc +%FT%TZ): Releasing new server version. $BUILD_VERSION"

echo "$(date --utc +%FT%TZ): Running build..."

docker compose rm -f server
docker compose build

OLD_CONTAINER=$(docker ps -aqf "name=server")
echo "$(date --utc +%FT%TZ): Scaling server up..."
docker compose up -d --no-deps --scale server=2 --no-recreate server

sleep 30

echo "$(date --utc +%FT%TZ): Scaling old server down..."
if [ -n "$OLD_CONTAINER" ]; then
  docker container rm -f "$OLD_CONTAINER"
fi
docker compose up -d --no-deps --scale server=1 --no-recreate server

echo "$(date --utc +%FT%TZ): Reloading caddy..."
CADDY_CONTAINER=$(docker ps -aqf "name=caddy")
docker exec "$CADDY_CONTAINER" caddy reload -c /etc/caddy/Caddyfile
