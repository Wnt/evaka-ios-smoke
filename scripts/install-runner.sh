#!/bin/sh
# SPDX-FileCopyrightText: 2017-2026 City of Espoo
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# Installs the GitHub Actions self-hosted runner for this repository on a Mac
# and starts it as a LaunchAgent of the logged-in user, which gives it the GUI
# session the iOS simulator needs. Can be run again: the steps already done
# are skipped.
#
# RUNNER_TOKEN is a registration token, needed only for the first run:
#   gh api -X POST repos/Wnt/evaka-ios-smoke/actions/runners/registration-token --jq .token

set -eu

REPO_URL=https://github.com/Wnt/evaka-ios-smoke
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"

PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:$PATH"
for tool in mise colima docker xcrun; do
  command -v "$tool" >/dev/null || echo "warning: $tool not found, the tests need it" >&2
done

case "$(uname -m)" in
  arm64) arch=arm64 ;;
  x86_64) arch=x64 ;;
  *) echo "Unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -x ./config.sh ]; then
  version=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest |
    sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')
  echo "Downloading actions/runner $version for osx-$arch"
  curl -fsSL -o runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v$version/actions-runner-osx-$arch-$version.tar.gz"
  tar xzf runner.tar.gz
  rm runner.tar.gz
fi

if [ ! -f .runner ]; then
  : "${RUNNER_TOKEN:?Set RUNNER_TOKEN to a runner registration token}"
  ./config.sh --unattended --url "$REPO_URL" --token "$RUNNER_TOKEN" \
    --labels ios-smoke --name "$(hostname -s)"
fi

if [ ! -f .service ]; then
  ./svc.sh install
fi

# svc.sh loads the LaunchAgent into the session it runs in. Over ssh that is
# a background session without the window server, so the agent is bootstrapped
# into the GUI session of the logged-in user instead, which from ssh only
# works as root.
plist="$HOME/Library/LaunchAgents/$(cat .service)"
uid=$(id -u)
if launchctl print "gui/$uid/$(basename "$plist" .plist)" >/dev/null 2>&1; then
  echo "The runner is already loaded in the GUI session"
else
  sudo launchctl bootstrap "gui/$uid" "$plist"
fi
./svc.sh status
