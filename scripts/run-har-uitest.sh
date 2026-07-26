#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

PRODUCT="${PRODUCT:-default}"
BUILD_MODE="${BUILD_MODE:-test}"
ENTRY_MODULE="${ENTRY_MODULE:-entry}"
ENTRY_TARGET="${ENTRY_TARGET:-default}"
HAR_MODULE_NAME="${HAR_MODULE_NAME:-main}"
HAR_MODULE_DIR="${HAR_MODULE_DIR:-feature/main}"
BUNDLE_NAME="${BUNDLE_NAME:-com.joker.kit}"
TEST_MODULE_NAME="${TEST_MODULE_NAME:-main_test}"
TEST_TIMEOUT_MS="${TEST_TIMEOUT_MS:-15000}"
TEST_SCOPE="${TEST_SCOPE:-}"
SKIP_BUILD="${SKIP_BUILD:-0}"

find_hvigorw() {
  if [[ -n "${HVIGORW:-}" ]]; then
    printf '%s\n' "${HVIGORW}"
  elif command -v hvigorw >/dev/null 2>&1; then
    command -v hvigorw
  elif [[ -n "${DEVECO_STUDIO_HOME:-}" &&
    -x "${DEVECO_STUDIO_HOME}/tools/hvigor/bin/hvigorw" ]]; then
    printf '%s\n' "${DEVECO_STUDIO_HOME}/tools/hvigor/bin/hvigorw"
  elif [[ -x "/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw" ]]; then
    printf '%s\n' "/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"
  else
    return 1
  fi
}

find_hdc() {
  if [[ -n "${HDC:-}" ]]; then
    printf '%s\n' "${HDC}"
  elif command -v hdc >/dev/null 2>&1; then
    command -v hdc
  elif [[ -n "${HARMONYOS_SDK_HOME:-}" &&
    -x "${HARMONYOS_SDK_HOME}/openharmony/toolchains/hdc" ]]; then
    printf '%s\n' "${HARMONYOS_SDK_HOME}/openharmony/toolchains/hdc"
  elif [[ -n "${DEVECO_STUDIO_HOME:-}" &&
    -x "${DEVECO_STUDIO_HOME}/sdk/default/openharmony/toolchains/hdc" ]]; then
    printf '%s\n' "${DEVECO_STUDIO_HOME}/sdk/default/openharmony/toolchains/hdc"
  elif [[ -x "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc" ]]; then
    printf '%s\n' "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
  else
    return 1
  fi
}

HVIGORW_BIN="$(find_hvigorw)" || {
  printf 'Cannot find hvigorw. Set HVIGORW or DEVECO_STUDIO_HOME.\n' >&2
  exit 1
}
HDC_BIN="$(find_hdc)" || {
  printf 'Cannot find hdc. Set HDC, HARMONYOS_SDK_HOME, or DEVECO_STUDIO_HOME.\n' >&2
  exit 1
}

ENTRY_HAP="${ENTRY_HAP:-${ENTRY_MODULE}/build/${PRODUCT}/outputs/${PRODUCT}/${ENTRY_MODULE}-${PRODUCT}-signed.hap}"
TEST_HAP="${TEST_HAP:-${HAR_MODULE_DIR}/build/${PRODUCT}/outputs/ohosTest/${HAR_MODULE_NAME}-ohosTest-signed.hap}"
REMOTE_DIR="/data/local/tmp/har_uitest_$$"
RESULT_FILE="$(mktemp -t har-uitest-result.XXXXXX)"
REMOTE_DIR_CREATED=0

cleanup() {
  if [[ "${REMOTE_DIR_CREATED}" == "1" ]]; then
    "${HDC_BIN}" shell rm -rf "${REMOTE_DIR}" >/dev/null 2>&1 || true
  fi
  rm -f "${RESULT_FILE}"
}
trap cleanup EXIT

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Required signed HAP not found: %s\n' "$1" >&2
    printf 'Configure project signing in DevEco Studio, then run this script again.\n' >&2
    exit 1
  fi
}

if [[ "${SKIP_BUILD}" != "1" ]]; then
  rm -f "${ENTRY_HAP}" "${TEST_HAP}"

  "${HVIGORW_BIN}" assembleHap \
    --mode module \
    -p "module=${ENTRY_MODULE}@${ENTRY_TARGET}" \
    -p "product=${PRODUCT}" \
    -p "buildMode=${BUILD_MODE}" \
    --no-daemon

  "${HVIGORW_BIN}" genOnDeviceTestHap \
    --mode module \
    -p "module=${HAR_MODULE_NAME}@ohosTest" \
    -p "product=${PRODUCT}" \
    -p "buildMode=${BUILD_MODE}" \
    -p isOhosTest=true \
    --no-daemon
fi

require_file "${ENTRY_HAP}"
require_file "${TEST_HAP}"

"${HDC_BIN}" list targets
"${HDC_BIN}" uninstall "${BUNDLE_NAME}" >/dev/null 2>&1 || true
"${HDC_BIN}" shell mkdir "${REMOTE_DIR}"
REMOTE_DIR_CREATED=1
"${HDC_BIN}" file send "${ENTRY_HAP}" "${REMOTE_DIR}/"
"${HDC_BIN}" file send "${TEST_HAP}" "${REMOTE_DIR}/"
"${HDC_BIN}" shell bm install -p "${REMOTE_DIR}"
"${HDC_BIN}" shell rm -rf "${REMOTE_DIR}"
REMOTE_DIR_CREATED=0

TEST_ARGS=(
  shell aa test
  -b "${BUNDLE_NAME}"
  -m "${TEST_MODULE_NAME}"
  -s unittest /ets/testrunner/OpenHarmonyTestRunner
)
if [[ -n "${TEST_SCOPE}" ]]; then
  TEST_ARGS+=(-s class "${TEST_SCOPE}")
fi
TEST_ARGS+=(
  -s timeout "${TEST_TIMEOUT_MS}"
  -s coverage false
)

set +e
"${HDC_BIN}" "${TEST_ARGS[@]}" | tee "${RESULT_FILE}"
TEST_COMMAND_STATUS="${PIPESTATUS[0]}"
set -e

if [[ "${TEST_COMMAND_STATUS}" != "0" ]]; then
  printf 'Device test command failed with status %s.\n' "${TEST_COMMAND_STATUS}" >&2
  exit "${TEST_COMMAND_STATUS}"
fi

if ! grep -Eq \
  'OHOS_REPORT_RESULT:.*Tests run: [1-9][0-9]*, Failure: 0, Error: 0, Pass: [1-9][0-9]*' \
  "${RESULT_FILE}"; then
  printf 'HAR UITest failed or produced no test result.\n' >&2
  exit 1
fi

if ! grep -q 'OHOS_REPORT_CODE: 0' "${RESULT_FILE}"; then
  printf 'HAR UITest reported a non-zero result code.\n' >&2
  exit 1
fi

printf 'HAR module UITest passed.\n'
