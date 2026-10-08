# shellcheck shell=sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Sourced by the other scripts. launchd starts the GitHub Actions runner with
# a minimal PATH, so the tools are put on it explicitly: mise's shims resolve
# node, yarn, java and pm2 from the eVaka checkout's mise.toml; colima and
# docker come from Homebrew (Apple Silicon) or MacPorts (Intel).

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EVAKA_DIR="$(mkdir -p "${EVAKA_DIR:-$REPO_DIR/evaka}" && cd "${EVAKA_DIR:-$REPO_DIR/evaka}" && pwd)"
export EVAKA_DIR

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export LANG="${LANG:-en_US.UTF-8}"
export MISE_YES=1
# A pm2 daemon of its own, so that stack-down.sh leaves other pm2 processes
# on the machine alone
export PM2_HOME="$HOME/.pm2-evaka-ios-smoke"
