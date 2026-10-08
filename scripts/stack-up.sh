#!/bin/sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Starts the eVaka development stack in EVAKA_DIR like `mise start` does,
# without the tunnel, and waits until it answers

set -eu
# shellcheck source=scripts/env.sh
. "$(dirname "$0")/env.sh"

STARTUP_TIMEOUT_SECONDS="${STARTUP_TIMEOUT_SECONDS:-1200}"

cd "$EVAKA_DIR"
mise trust "$EVAKA_DIR/mise.toml"
mise install

if ! docker info >/dev/null 2>&1; then
  colima start
fi

(cd compose && docker compose up -d)
(cd frontend && yarn install --immutable)
(cd compose && pm2 start ecosystem.config.js)

# The service is built with gradle on the first run, which takes a while
deadline=$(($(date +%s) + STARTUP_TIMEOUT_SECONDS))
for target in apigw:3000 service:8888 frontend:9099; do
  name="${target%%:*}"
  port="${target##*:}"
  until curl -s -o /dev/null "http://localhost:$port"; do
    if [ "$(date +%s)" -gt "$deadline" ]; then
      echo "$name did not answer on port $port in $STARTUP_TIMEOUT_SECONDS seconds" >&2
      pm2 status || true
      pm2 logs --nostream --lines 100 "$name" || true
      exit 1
    fi
    sleep 5
  done
  echo "$name is up (port $port)"
done
