#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_SOURCE="${PROJECT_ROOT}/feature/main/src/ohosTest/ets/test"

violations="$(
  rg -n '\.delayMs\(' "${TEST_SOURCE}" \
    --glob '*.ets' \
    | rg -v '/framework/UiDriver\.ets:' \
    || true
)"

if [[ -n "${violations}" ]]; then
  printf 'Direct delayMs calls are not allowed outside framework/UiDriver.ets:\n' >&2
  printf '%s\n' "${violations}" >&2
  exit 1
fi

scroll_prewaits="$(
  rg -n 'waitForComponent\(ON\.text\(text\), [0-9]+\)' \
    "${TEST_SOURCE}/framework/UiDriver.ets" \
    || true
)"

if [[ -n "${scroll_prewaits}" ]]; then
  printf 'Scroll lookup must probe the current viewport without waiting:\n' >&2
  printf '%s\n' "${scroll_prewaits}" >&2
  exit 1
fi

printf 'ok - UITest waits are centralized; the ability restart exception stays in UiDriver.ets\n'
