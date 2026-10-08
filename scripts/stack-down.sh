#!/bin/sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Stops what stack-up.sh started. Never fails, so that it can always run at
# the end of a job.

set -u
# shellcheck source=scripts/env.sh
. "$(dirname "$0")/env.sh"

cd "$EVAKA_DIR" || exit 0
pm2 delete all || true
pm2 kill || true
(cd compose && docker compose down) || true
exit 0
