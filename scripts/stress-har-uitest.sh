#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -gt 1 || ("$#" == "1" && ! "$1" =~ ^[1-9][0-9]*$) ]]; then
  printf 'Usage: scripts/stress-har-uitest.sh [positive-run-count]\n' >&2
  exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUN_COUNT="${1:-10}"
RESULT_DIR="${PROJECT_ROOT}/build/uitest-lifecycle-stress"
mkdir -p "${RESULT_DIR}"

for ((run = 1; run <= RUN_COUNT; run++)); do
  RESULT_FILE="${RESULT_DIR}/run-${run}.log"
  printf 'Lifecycle stress run %d/%d\n' "${run}" "${RUN_COUNT}"

  set +e
  "${PROJECT_ROOT}/uitest" LifecycleStressUiTest 2>&1 | tee "${RESULT_FILE}"
  TEST_STATUS="${PIPESTATUS[0]}"
  set -e

  if [[ "${TEST_STATUS}" != "0" ]]; then
    printf 'Lifecycle stress reproduced a stopped/incomplete runner at run %d; log: %s\n' \
      "${run}" "${RESULT_FILE}" >&2
    exit "${TEST_STATUS}"
  fi
done

printf 'Lifecycle stress completed %d/%d runs without a stopped runner.\n' \
  "${RUN_COUNT}" "${RUN_COUNT}"
