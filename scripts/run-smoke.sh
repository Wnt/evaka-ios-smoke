#!/bin/sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Runs the tests inside the eVaka checkout: they import eVaka's e2e test
# fixtures and API clients and run with eVaka's node_modules

set -eu
# shellcheck source=scripts/env.sh
. "$(dirname "$0")/env.sh"

frontend="$EVAKA_DIR/frontend"
rsync -a --delete "$REPO_DIR/src/" "$frontend/src/ios-smoke/"

cd "$frontend"
rm -rf ios-smoke-results
src/ios-smoke/setup.sh

status=0
npx vitest run --config src/ios-smoke/vitest.config.ts || status=$?

rm -rf "$REPO_DIR/results"
if [ -d ios-smoke-results ]; then
  cp -R ios-smoke-results "$REPO_DIR/results"
fi
exit "$status"
