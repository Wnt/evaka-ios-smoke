#!/bin/sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Clones eVaka into EVAKA_DIR or updates an existing clone to EVAKA_REF (a
# branch, tag or commit). Untracked and ignored files (node_modules, .appium,
# the copied tests) are kept between runs.

set -eu
# shellcheck source=scripts/env.sh
. "$(dirname "$0")/env.sh"

EVAKA_REPO="${EVAKA_REPO:-https://github.com/espoon-voltti/evaka.git}"
EVAKA_REF="${EVAKA_REF:-master}"

if [ ! -d "$EVAKA_DIR/.git" ]; then
  git clone "$EVAKA_REPO" "$EVAKA_DIR"
fi
cd "$EVAKA_DIR"
git remote set-url origin "$EVAKA_REPO"
git fetch origin "$EVAKA_REF"
git checkout --force --detach FETCH_HEAD
git log -1 --format='eVaka at %H (%cd) %s'
