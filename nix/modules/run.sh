#!/usr/bin/env bash
set -u

APP_USER="${1:?usage: run <user>}"
HOME_DIR="/home/$APP_USER"
LOG="$HOME_DIR/cron/run.log"
LOCK="$HOME_DIR/cron/run.lock"
TARGET="$HOME_DIR/app/scripts/ci.sh"

mkdir -p "$HOME_DIR/cron"

if ! test -x "$TARGET"; then
  echo "$(date -Is) warn: $TARGET missing, skipping" >> "$LOG"
  exit 0
fi

export HOME="$HOME_DIR"

if ! cd "$HOME_DIR/app"; then
  echo "$(date -Is) error: cannot cd $HOME_DIR/app" >> "$LOG"
  exit 1
fi

exec flock -n "$LOCK" bash "$TARGET" >> "$LOG" 2>&1
