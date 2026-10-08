<!--
SPDX-FileCopyrightText: 2017-2026 City of Espoo

SPDX-License-Identifier: LGPL-2.1-or-later
-->

# eVaka iOS smoke tests

Two regression tests for iOS WebKit layout bugs in the
[eVaka](https://github.com/espoon-voltti/evaka) citizen app when it is
installed on the iPhone home screen:

- the reservation and absence modal buttons in the calendar are drawn on the
  screen, not just reported as visible
- the header and the bottom navigation stay where they belong when iOS leaves
  the visual viewport stale after the keyboard closes and the device rotates

The tests drive the citizen app as a home screen web clip in the iOS
Simulator with Appium. Playwright's Chromium, which runs eVaka's own E2E
tests, does not reproduce these bugs.

## Why this is not in the eVaka repository

The tests need macOS, Xcode and an iOS simulator, which eVaka's CI does not
have. They run here on a self-hosted Mac a few times a day against eVaka
`master` instead of on every pull request.

The test code imports eVaka's own E2E test modules (the dev API fixtures,
the generated API clients, the test config and `lib-common`) and runs with
eVaka's `node_modules`. So at run time the scripts clone eVaka, copy `src/`
to `frontend/src/ios-smoke/` in that clone and run vitest there. `src/` is
kept as it was in eVaka (`frontend/src/ios-smoke`), so its README and error
messages still refer to the `yarn ios-smoke` scripts of that location;
`scripts/run-smoke.sh` runs the same commands.

## Layout

```
src/                     the tests, copied into eVaka's frontend/src/ios-smoke at run time
scripts/
  evaka-checkout.sh      clone eVaka or update the clone to EVAKA_REF
  stack-up.sh            start eVaka's dev stack (docker compose + pm2) and wait for it
  run-smoke.sh           copy the tests into the clone, install Appium, run vitest
  stack-down.sh          stop the stack
  install-runner.sh      set up the GitHub Actions runner on a Mac
  env.sh                 PATH and shared settings, sourced by the others
.github/workflows/       the scheduled workflow
```

The scripts are configured with environment variables:

| Variable | Default | |
|---|---|---|
| `EVAKA_DIR` | `./evaka` | the eVaka clone the scripts manage |
| `EVAKA_REPO` | `https://github.com/espoon-voltti/evaka.git` | |
| `EVAKA_REF` | `master` | branch, tag or commit to test |
| `STARTUP_TIMEOUT_SECONDS` | `1200` | how long `stack-up.sh` waits for the stack |

`evaka-checkout.sh` force checks out `EVAKA_REF` and discards changes to
tracked files, so do not point `EVAKA_DIR` at a checkout you work in.

## Running locally

Prerequisites:

- macOS with Xcode and an iOS 26 simulator runtime
  (`xcodebuild -downloadPlatform iOS`)
- [mise](https://mise.jdx.dev/) installed at `~/.local/bin/mise`
  (`curl https://mise.run | sh`); it installs node, yarn, java and pm2 from
  eVaka's `mise.toml`
- Docker with the compose plugin, for example with colima: on Apple Silicon
  `brew install colima docker docker-compose`, on an Intel Mac (Homebrew no
  longer supports it) `sudo port install colima docker docker-compose-plugin`
  from MacPorts. Add the package manager's `cli-plugins` directory to
  `cliPluginsExtraDirs` in `~/.docker/config.json` so that `docker compose`
  works. `stack-up.sh` runs `colima start` when `docker info` fails.
- The default eVaka ports free (frontend 9099, apigw 3000, service 8888,
  dummy IdP 9090, Postgres 5432 and the other compose services)

Then:

```sh
scripts/evaka-checkout.sh && scripts/stack-up.sh && scripts/run-smoke.sh
scripts/stack-down.sh
```

The first `stack-up.sh` builds the service with gradle and takes several
minutes. Appium's log and screenshots of failed tests are copied to
`results/`. The pm2 processes run under their own `PM2_HOME`
(`~/.pm2-evaka-ios-smoke`), so `stack-down.sh` does not touch other pm2
processes; it does run `docker compose down` in eVaka's `compose/`, which
stops a dev stack started from another checkout too, since they share the
compose project name.

If an eVaka dev stack with the dev API is already running, the tests can be
run against it with only `scripts/run-smoke.sh` after `evaka-checkout.sh`.

## The runner

`.github/workflows/ios-smoke.yml` runs at 05:00, 11:00 and 17:00 UTC and on
demand (with an optional eVaka ref) on a self-hosted runner with the labels
`self-hosted`, `macOS` and `ios-smoke`. The eVaka clone is kept in
`~/evaka-ios-smoke/evaka` between runs, so `node_modules`, the gradle caches,
Appium and the simulator's home screen icon are reused. Every run updates the
clone, starts the stack, runs the tests, uploads `results/` as the
`ios-smoke-results` artifact and stops the stack.

To set up the Mac:

1. Install the prerequisites above and check that a local run works.
2. Turn on automatic login for the runner's user (System Settings → Users &
   Groups; needs FileVault off) and turn off sleep and the screen lock, for
   example `sudo pmset -a sleep 0 displaysleep 0`. The runner is a
   LaunchAgent, which runs only in a logged-in GUI session, and the
   simulator needs that session.
3. Install the runner:

   ```sh
   RUNNER_TOKEN=$(gh api -X POST repos/Wnt/evaka-ios-smoke/actions/runners/registration-token --jq .token) \
     scripts/install-runner.sh
   ```

   It downloads the latest `actions/runner` into `~/actions-runner`
   (`RUNNER_DIR`), registers it with the label `ios-smoke` and the machine's
   host name and installs and starts it with `svc.sh`. Running it again skips
   the steps already done.

launchd starts the runner with a minimal environment, so `scripts/env.sh`
puts mise's shims, `~/.local/bin` and Homebrew on `PATH` itself.

## What the tests check

- **Calendar modal buttons are drawn whole on the screen**: the reservation
  and absence modal footer buttons are inside the viewport, on top in hit
  testing and actually painted on screen. iOS WebKit can paint a
  `position: fixed` modal clipped by the app's scrolling area while geometry,
  hit testing and even real taps still report the button as visible (fixed
  in eVaka PR #9975).
- **Header and bottom navigation stay in place with a stale visual
  viewport**: after a reply is sent in landscape and the device rotates back,
  iOS WebKit can leave the visual viewport stale and resolve `position: fixed`
  against it (WebKit bugs 254861 and 297779). The test drives the simulator
  into that state with a recorded user sequence and checks that the header
  and the bottom navigation are laid out and painted where they were before
  (the app shell layout of eVaka PR #9798).

The painted position is measured from a lossless simulator screenshot: the
element is coloured magenta and the bounding box of the magenta pixels is
compared with the layout. See [src/README.md](src/README.md) for more on how
the tests work and how to recover a stuck simulator.

## Licence

LGPL-2.1-or-later, the same as eVaka. See [LICENSE](LICENSE).
