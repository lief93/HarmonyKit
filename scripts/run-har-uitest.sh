#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

ENTRY_HAP_WAS_SET=0
TEST_HAP_WAS_SET=0
[[ -n "${ENTRY_HAP+x}" ]] && ENTRY_HAP_WAS_SET=1
[[ -n "${TEST_HAP+x}" ]] && TEST_HAP_WAS_SET=1

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
DEVICE_ID="${DEVICE_ID:-}"
EVIDENCE_FILE="${EVIDENCE_FILE:-}"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

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

single_line() {
  printf '%s' "$1" |
    tr '\r\n' '  ' |
    sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    fail 'Cannot find shasum, sha256sum, or openssl for evidence hashing.'
  fi
}

sha256_text() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$1" | openssl dgst -sha256 | awk '{print $NF}'
  else
    fail 'Cannot find shasum, sha256sum, or openssl for evidence hashing.'
  fi
}

format_command() {
  local formatted=""
  local argument
  local quoted
  for argument in "$@"; do
    printf -v quoted '%q' "${argument}"
    if [[ -n "${formatted}" ]]; then
      formatted+=" "
    fi
    formatted+="${quoted}"
  done
  printf '%s' "${formatted}"
}

detect_deveco_version() {
  local plist
  local candidate_home="${DEVECO_STUDIO_HOME:-}"
  for plist in \
    "${candidate_home}/Info.plist" \
    "${candidate_home}/../Info.plist" \
    "/Applications/DevEco-Studio.app/Contents/Info.plist"; do
    if [[ -f "${plist}" && -x "/usr/libexec/PlistBuddy" ]]; then
      /usr/libexec/PlistBuddy \
        -c 'Print :CFBundleShortVersionString' "${plist}" 2>/dev/null &&
        return 0
    fi
  done
  printf 'unknown\n'
}

HVIGORW_BIN="$(find_hvigorw)" || {
  printf 'Cannot find hvigorw. Set HVIGORW or DEVECO_STUDIO_HOME.\n' >&2
  exit 1
}
if [[ -z "${DEVECO_SDK_HOME:-}" &&
  "${HVIGORW_BIN}" == */Contents/tools/hvigor/bin/hvigorw ]]; then
  DEVECO_SDK_HOME="${HVIGORW_BIN%/tools/hvigor/bin/hvigorw}/sdk"
  export DEVECO_SDK_HOME
fi
HDC_BIN="$(find_hdc)" || {
  printf 'Cannot find hdc. Set HDC, HARMONYOS_SDK_HOME, or DEVECO_STUDIO_HOME.\n' >&2
  exit 1
}

if [[ "${SKIP_BUILD}" != "0" && "${SKIP_BUILD}" != "1" ]]; then
  fail 'SKIP_BUILD must be 0 or 1.'
fi

DEFAULT_ENTRY_SIGNED_HAP="${ENTRY_MODULE}/build/${PRODUCT}/outputs/${PRODUCT}/${ENTRY_MODULE}-${PRODUCT}-signed.hap"
DEFAULT_ENTRY_UNSIGNED_HAP="${ENTRY_MODULE}/build/${PRODUCT}/outputs/${PRODUCT}/${ENTRY_MODULE}-${PRODUCT}-unsigned.hap"
DEFAULT_TEST_SIGNED_HAP="${HAR_MODULE_DIR}/build/${PRODUCT}/outputs/ohosTest/${HAR_MODULE_NAME}-ohosTest-signed.hap"
DEFAULT_TEST_UNSIGNED_HAP="${HAR_MODULE_DIR}/build/${PRODUCT}/outputs/ohosTest/${HAR_MODULE_NAME}-ohosTest-unsigned.hap"
if [[ "${SKIP_BUILD}" == "0" ]]; then
  if [[ "${ENTRY_HAP_WAS_SET}" == "1" || "${TEST_HAP_WAS_SET}" == "1" ]]; then
    fail 'ENTRY_HAP and TEST_HAP cannot be overridden when SKIP_BUILD=0; build mode owns and cleans only repository default outputs.'
  fi
  ENTRY_HAP="${DEFAULT_ENTRY_SIGNED_HAP}"
  TEST_HAP="${DEFAULT_TEST_SIGNED_HAP}"
else
  ENTRY_HAP="${ENTRY_HAP:-${DEFAULT_ENTRY_SIGNED_HAP}}"
  TEST_HAP="${TEST_HAP:-${DEFAULT_TEST_SIGNED_HAP}}"
  printf '%s\n' \
    'WARNING: SKIP_BUILD=1 is for local debugging only and cannot be used as acceptance evidence.' >&2
  if [[ -n "${EVIDENCE_FILE}" ]]; then
    fail 'EVIDENCE_FILE cannot be used with SKIP_BUILD=1.'
  fi
fi

REMOTE_DIR="/data/local/tmp/har_uitest_$$"
RESULT_FILE="$(mktemp -t har-uitest-result.XXXXXX)"
NORMALIZED_RESULT_FILE="$(mktemp -t har-uitest-normalized.XXXXXX)"
REMOTE_DIR_CREATED=0
SELECTED_DEVICE_ID=""
DEVICE_CONNECT_KEY_SHA256=""
DEVICE_KIND="unknown"
HAP_SIGNING_STATUS="prebuilt-debug-unverified"
HDC_DEVICE=()
EVIDENCE_TEMP=""

cleanup() {
  if [[ "${REMOTE_DIR_CREATED}" == "1" && -n "${SELECTED_DEVICE_ID}" ]]; then
    "${HDC_DEVICE[@]}" shell rm -rf "${REMOTE_DIR}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${EVIDENCE_TEMP}" && -f "${EVIDENCE_TEMP}" ]]; then
    rm -f "${EVIDENCE_TEMP}"
  fi
  rm -f "${RESULT_FILE}" "${NORMALIZED_RESULT_FILE}"
}
trap cleanup EXIT

select_device() {
  local targets_output
  local list_status
  local target
  local matched=0
  CONNECTED_TARGETS=()

  set +e
  targets_output="$("${HDC_BIN}" list targets 2>&1)"
  list_status=$?
  set -e
  if [[ "${list_status}" != "0" ]]; then
    printf '%s\n' "${targets_output}" >&2
    fail "Cannot list HDC targets; hdc exited with status ${list_status}."
  fi
  if printf '%s\n' "${targets_output}" |
    grep -Eq '\[Fail\]\[E[0-9]{6}\]'; then
    printf '%s\n' "${targets_output}" >&2
    fail 'Cannot list HDC targets because HDC reported a failure marker.'
  fi

  while IFS= read -r target; do
    target="${target%$'\r'}"
    if [[ -n "${target}" && "${target}" != "[Empty]" ]]; then
      CONNECTED_TARGETS+=("${target}")
    fi
  done <<<"${targets_output}"

  if [[ "${#CONNECTED_TARGETS[@]}" == "0" ]]; then
    fail 'No HDC target is connected. Connect one device or emulator and retry.'
  fi

  if [[ -n "${DEVICE_ID}" ]]; then
    for target in "${CONNECTED_TARGETS[@]}"; do
      if [[ "${target}" == "${DEVICE_ID}" ]]; then
        matched=1
        break
      fi
    done
    if [[ "${matched}" != "1" ]]; then
      fail 'DEVICE_ID is not connected. Use an exact connect key from `hdc list targets`.'
    fi
    SELECTED_DEVICE_ID="${DEVICE_ID}"
  elif [[ "${#CONNECTED_TARGETS[@]}" == "1" ]]; then
    SELECTED_DEVICE_ID="${CONNECTED_TARGETS[0]}"
  else
    fail 'Multiple HDC targets are connected. Set DEVICE_ID to the exact connect key to avoid operating on another device.'
  fi

  HDC_DEVICE=("${HDC_BIN}" -t "${SELECTED_DEVICE_ID}")
  DEVICE_CONNECT_KEY_SHA256="$(sha256_text "${SELECTED_DEVICE_ID}")"
  if [[ "${SELECTED_DEVICE_ID}" == 127.0.0.1:* ||
    "${SELECTED_DEVICE_ID}" == localhost:* ]]; then
    DEVICE_KIND="emulator"
  else
    DEVICE_KIND="physical-or-remote"
  fi
}

run_hdc() {
  local output
  local status
  set +e
  output="$("${HDC_DEVICE[@]}" "$@" 2>&1)"
  status=$?
  set -e
  if [[ -n "${output}" ]]; then
    printf '%s\n' "${output}"
  fi
  if [[ "${status}" != "0" ]]; then
    return "${status}"
  fi
  if printf '%s\n' "${output}" |
    grep -Eq '\[Fail\]\[E[0-9]{6}\]'; then
    return 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Required signed HAP not found: %s\n' "$1" >&2
    printf 'Configure project signing in DevEco Studio, then run this script again.\n' >&2
    exit 1
  fi
}

ENTRY_BUILD_ARGS=(
  assembleHap
  --mode module
  -p "module=${ENTRY_MODULE}@${ENTRY_TARGET}"
  -p "product=${PRODUCT}"
  -p "buildMode=${BUILD_MODE}"
  --no-daemon
)
TEST_BUILD_ARGS=(
  genOnDeviceTestHap
  --mode module
  -p "module=${HAR_MODULE_NAME}@ohosTest"
  -p "product=${PRODUCT}"
  -p "buildMode=${BUILD_MODE}"
  -p isOhosTest=true
  --no-daemon
)

select_device

if [[ "${SKIP_BUILD}" == "0" ]]; then
  rm -f \
    "${DEFAULT_ENTRY_SIGNED_HAP}" \
    "${DEFAULT_ENTRY_UNSIGNED_HAP}" \
    "${DEFAULT_TEST_SIGNED_HAP}" \
    "${DEFAULT_TEST_UNSIGNED_HAP}"
  "${HVIGORW_BIN}" "${ENTRY_BUILD_ARGS[@]}"
  "${HVIGORW_BIN}" "${TEST_BUILD_ARGS[@]}"
  if [[ -f "${DEFAULT_ENTRY_SIGNED_HAP}" &&
    -f "${DEFAULT_TEST_SIGNED_HAP}" ]]; then
    ENTRY_HAP="${DEFAULT_ENTRY_SIGNED_HAP}"
    TEST_HAP="${DEFAULT_TEST_SIGNED_HAP}"
    HAP_SIGNING_STATUS="signed"
  elif [[ "${DEVICE_KIND}" == "emulator" &&
    -f "${DEFAULT_ENTRY_UNSIGNED_HAP}" &&
    -f "${DEFAULT_TEST_UNSIGNED_HAP}" ]]; then
    ENTRY_HAP="${DEFAULT_ENTRY_UNSIGNED_HAP}"
    TEST_HAP="${DEFAULT_TEST_UNSIGNED_HAP}"
    HAP_SIGNING_STATUS="unsigned-emulator"
    printf '%s\n' \
      'WARNING: Fresh unsigned HAPs are accepted only for this explicitly selected loopback emulator.' >&2
  else
    fail 'Fresh signed HAPs were not generated. Configure signing for physical/remote devices; unsigned HAPs are allowed only on an explicitly selected loopback emulator.'
  fi
fi

require_file "${ENTRY_HAP}"
require_file "${TEST_HAP}"

"${HDC_DEVICE[@]}" uninstall "${BUNDLE_NAME}" >/dev/null 2>&1 || true
run_hdc shell mkdir "${REMOTE_DIR}"
REMOTE_DIR_CREATED=1
run_hdc file send "${ENTRY_HAP}" "${REMOTE_DIR}/"
run_hdc file send "${TEST_HAP}" "${REMOTE_DIR}/"
run_hdc shell bm install -p "${REMOTE_DIR}"
run_hdc shell rm -rf "${REMOTE_DIR}"
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
"${HDC_DEVICE[@]}" "${TEST_ARGS[@]}" 2>&1 | tee "${RESULT_FILE}"
TEST_COMMAND_STATUS="${PIPESTATUS[0]}"
set -e
tr -d '\r' <"${RESULT_FILE}" >"${NORMALIZED_RESULT_FILE}"

if [[ "${TEST_COMMAND_STATUS}" != "0" ]]; then
  printf 'Device test command failed with status %s.\n' "${TEST_COMMAND_STATUS}" >&2
  exit "${TEST_COMMAND_STATUS}"
fi

if grep -Eq '\[Fail\]\[E[0-9]{6}\]' "${NORMALIZED_RESULT_FILE}"; then
  printf 'HAR UITest output contains an HDC failure marker.\n' >&2
  exit 1
fi

RESULT_LINES=()
while IFS= read -r line; do
  RESULT_LINES+=("${line}")
done < <(grep '^OHOS_REPORT_RESULT:' "${NORMALIZED_RESULT_FILE}" || true)
if [[ "${#RESULT_LINES[@]}" != "1" ]]; then
  printf 'HAR UITest must produce exactly one OHOS_REPORT_RESULT line; found %s.\n' \
    "${#RESULT_LINES[@]}" >&2
  exit 1
fi

FINAL_RESULT_LINE="${RESULT_LINES[0]}"
RESULT_PATTERN='^OHOS_REPORT_RESULT: stream=Tests run: ([0-9]+), Failure: ([0-9]+), Error: ([0-9]+), Pass: ([0-9]+), Ignore: ([0-9]+)$'
if [[ ! "${FINAL_RESULT_LINE}" =~ ${RESULT_PATTERN} ]]; then
  printf 'HAR UITest result line does not match the exact expected format.\n' >&2
  exit 1
fi
TESTS_RUN=$((10#${BASH_REMATCH[1]}))
FAILURE_COUNT=$((10#${BASH_REMATCH[2]}))
ERROR_COUNT=$((10#${BASH_REMATCH[3]}))
PASS_COUNT=$((10#${BASH_REMATCH[4]}))
IGNORE_COUNT=$((10#${BASH_REMATCH[5]}))
if [[ "${TESTS_RUN}" == "0" ||
  "${TESTS_RUN}" != "${PASS_COUNT}" ||
  "${FAILURE_COUNT}" != "0" ||
  "${ERROR_COUNT}" != "0" ||
  "${IGNORE_COUNT}" != "0" ]]; then
  printf 'HAR UITest counts are not an all-pass result: run=%s failure=%s error=%s pass=%s ignore=%s.\n' \
    "${TESTS_RUN}" "${FAILURE_COUNT}" "${ERROR_COUNT}" \
    "${PASS_COUNT}" "${IGNORE_COUNT}" >&2
  exit 1
fi

CODE_LINES=()
while IFS= read -r line; do
  CODE_LINES+=("${line}")
done < <(grep '^OHOS_REPORT_CODE:' "${NORMALIZED_RESULT_FILE}" || true)
if [[ "${#CODE_LINES[@]}" != "1" ||
  "${CODE_LINES[0]:-}" != "OHOS_REPORT_CODE: 0" ]]; then
  printf 'HAR UITest must produce exactly one precise OHOS_REPORT_CODE: 0 line.\n' >&2
  exit 1
fi
FINAL_CODE_LINE="${CODE_LINES[0]}"

query_device_property() {
  local property="$1"
  local value
  local status
  set +e
  value="$("${HDC_DEVICE[@]}" shell param get "${property}" 2>/dev/null)"
  status=$?
  set -e
  if [[ "${status}" == "0" ]] &&
    ! printf '%s\n' "${value}" |
      grep -Eq '\[Fail\]\[E[0-9]{6}\]'; then
    single_line "${value}"
  fi
}

write_evidence() {
  local target_commit
  local target_worktree_clean=false
  local worktree_status
  local deveco_version
  local hvigor_version
  local device_os_version
  local device_api_version
  local evidence_directory
  local entry_build_command
  local test_build_command
  local test_command
  local timestamp

  target_commit="$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"
  worktree_status="$(git -C "${PROJECT_ROOT}" status --porcelain)"
  if [[ -z "${worktree_status}" ]]; then
    target_worktree_clean=true
  fi
  deveco_version="$(single_line "$(detect_deveco_version)")"
  hvigor_version="$(single_line "$("${HVIGORW_BIN}" --version 2>&1)")"
  device_os_version="$(query_device_property const.ohos.fullname)"
  if [[ -z "${device_os_version}" ]]; then
    device_os_version="$(
      query_device_property const.product.software.version
    )"
  fi
  device_os_version="${device_os_version:-unknown}"
  device_api_version="$(
    query_device_property const.ohos.apiversion
  )"
  device_api_version="${device_api_version:-unknown}"
  entry_build_command="$(
    format_command "${HVIGORW_BIN}" "${ENTRY_BUILD_ARGS[@]}"
  )"
  test_build_command="$(
    format_command "${HVIGORW_BIN}" "${TEST_BUILD_ARGS[@]}"
  )"
  test_command="hdc -t <sha256:${DEVICE_CONNECT_KEY_SHA256}> $(format_command "${TEST_ARGS[@]}")"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  evidence_directory="$(dirname "${EVIDENCE_FILE}")"
  mkdir -p "${evidence_directory}"
  EVIDENCE_TEMP="$(
    mktemp "${evidence_directory}/.har-uitest-evidence.XXXXXX"
  )"
  {
    printf '# HAR module UITest device evidence\n\n'
    printf 'schema: harmony-kit.har-uitest-device-evidence.v1\n'
    printf 'recorded_at_utc: %s\n' "${timestamp}"
    printf 'target_commit: %s\n' "${target_commit}"
    printf 'target_worktree_clean: %s\n' "${target_worktree_clean}"
    printf 'runner: scripts/run-har-uitest.sh\n'
    printf 'skip_build: 0\n'
    printf 'acceptance_eligible: true\n'
    printf 'hap_signing_status: %s\n' "${HAP_SIGNING_STATUS}"
    printf 'product: %s\n' "${PRODUCT}"
    printf 'build_mode: %s\n' "${BUILD_MODE}"
    printf 'entry_module: %s\n' "${ENTRY_MODULE}"
    printf 'entry_target: %s\n' "${ENTRY_TARGET}"
    printf 'har_module_name: %s\n' "${HAR_MODULE_NAME}"
    printf 'har_module_dir: %s\n' "${HAR_MODULE_DIR}"
    printf 'bundle_name: %s\n' "${BUNDLE_NAME}"
    printf 'test_module_name: %s\n' "${TEST_MODULE_NAME}"
    printf 'test_scope: %s\n' "${TEST_SCOPE:-<all>}"
    printf 'test_timeout_ms: %s\n' "${TEST_TIMEOUT_MS}"
    printf 'device_kind: %s\n' "${DEVICE_KIND}"
    printf 'device_connect_key_sha256: %s\n' \
      "${DEVICE_CONNECT_KEY_SHA256}"
    printf 'device_os_version: %s\n' "${device_os_version}"
    printf 'device_api_version: %s\n' "${device_api_version}"
    printf 'deveco_version: %s\n' "${deveco_version}"
    printf 'deveco_sdk_home: %s\n' "${DEVECO_SDK_HOME:-<unset>}"
    printf 'hvigor_version: %s\n' "${hvigor_version}"
    printf 'entry_build_command: %s\n' "${entry_build_command}"
    printf 'test_build_command: %s\n' "${test_build_command}"
    printf 'test_command: %s\n' "${test_command}"
    printf 'entry_hap_path: %s\n' "${ENTRY_HAP}"
    printf 'entry_hap_bytes: %s\n' "$(wc -c <"${ENTRY_HAP}" | tr -d ' ')"
    printf 'entry_hap_sha256: %s\n' "$(sha256_file "${ENTRY_HAP}")"
    printf 'test_hap_path: %s\n' "${TEST_HAP}"
    printf 'test_hap_bytes: %s\n' "$(wc -c <"${TEST_HAP}" | tr -d ' ')"
    printf 'test_hap_sha256: %s\n' "$(sha256_file "${TEST_HAP}")"
    printf 'final_result: %s\n' "${FINAL_RESULT_LINE}"
    printf 'final_code: %s\n' "${FINAL_CODE_LINE}"
    printf 'test_shell_exit_status: %s\n' "${TEST_COMMAND_STATUS}"
    printf 'script_exit_status: 0\n'
  } >"${EVIDENCE_TEMP}"
  mv "${EVIDENCE_TEMP}" "${EVIDENCE_FILE}"
  EVIDENCE_TEMP=""
}

if [[ -n "${EVIDENCE_FILE}" ]]; then
  write_evidence
fi

printf 'HAR module UITest passed.\n'
