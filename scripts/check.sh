#!/usr/bin/env bash

echo "$(date --utc +%FT%TZ): Fetching remote repository..."
git fetch

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
  if [ -z "$(docker ps -qf "name=server")" ]; then
    echo "$(date --utc +%FT%TZ): No server running. Deploying..."
    ./scripts/deploy.sh
  else
    echo "$(date --utc +%FT%TZ): No changes detected"
  fi
elif [ $LOCAL = $BASE ]; then
  BUILD_VERSION=$(git rev-parse HEAD)
  echo "$(date --utc +%FT%TZ): Changes detected, deploying new version: $BUILD_VERSION"
  ./scripts/deploy.sh
elif [ $REMOTE = $BASE ]; then
  echo "$(date --utc +%FT%TZ): Local changes detected, stashing"
  git stash
  ./scripts/deploy.sh
else
  echo "$(date --utc +%FT%TZ): Git is diverged, this is unexpected."
fi
