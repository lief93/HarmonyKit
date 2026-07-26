#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${PROJECT_ROOT}/scripts/run-har-uitest.sh"
TEST_ROOT="$(mktemp -d -t har-uitest-tests.XXXXXX)"
PASS_COUNT=0
FAIL_COUNT=0
GENERATED_PROJECT_DIRS=()

PASS_REPORT=$'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0\nOHOS_REPORT_CODE: 0'

cleanup() {
  local path
  for path in "${GENERATED_PROJECT_DIRS[@]}"; do
    rm -rf "${path}"
  done
  rm -rf "${TEST_ROOT}"
}
trap cleanup EXIT

new_fixture() {
  local name="$1"
  FIXTURE="${TEST_ROOT}/${name}"
  mkdir -p "${FIXTURE}"
  ENTRY_FIXTURE_HAP="${FIXTURE}/entry-signed.hap"
  TEST_FIXTURE_HAP="${FIXTURE}/test-signed.hap"
  FAKE_HDC="${FIXTURE}/hdc"
  FAKE_HVIGOR="${FIXTURE}/hvigorw"
  FAKE_BIN_DIR="${FIXTURE}/bin"
  FAKE_GIT="${FAKE_BIN_DIR}/git"
  HDC_LOG="${FIXTURE}/hdc.log"
  HVIGOR_LOG="${FIXTURE}/hvigor.log"
  RUN_OUTPUT_FILE="${FIXTURE}/runner.log"
  mkdir -p "${FAKE_BIN_DIR}"
  printf 'entry-hap\n' >"${ENTRY_FIXTURE_HAP}"
  printf 'test-hap\n' >"${TEST_FIXTURE_HAP}"

  cat >"${FAKE_HDC}" <<'FAKE_HDC_SCRIPT'
#!/usr/bin/env bash
set -u

printf '%s\n' "$*" >>"${FAKE_HDC_LOG}"
if [[ "$*" == "list targets" ]]; then
  printf '%b' "${FAKE_TARGETS:-}"
  exit "${FAKE_LIST_EXIT:-0}"
fi
if [[ "$*" == *"param get const.ohos.fullname"* ||
  "$*" == *"param get const.product.software.version"* ]]; then
  printf '%s\n' "${FAKE_OS_VERSION:-OpenHarmony-5.0.5.310}"
  exit 0
fi
if [[ "$*" == *"param get const.ohos.apiversion"* ]]; then
  printf '%s\n' "${FAKE_API_VERSION:-18}"
  exit 0
fi
if [[ -n "${FAKE_FAIL_MATCH:-}" && "$*" == *"${FAKE_FAIL_MATCH}"* ]]; then
  printf '[Fail][E005003] synthetic HDC failure\n'
  exit "${FAKE_FAIL_EXIT:-7}"
fi
if [[ " $* " == *" shell aa test "* ]]; then
  printf '%b\n' "${FAKE_REPORT:-}"
  exit "${FAKE_TEST_EXIT:-0}"
fi
exit 0
FAKE_HDC_SCRIPT

  cat >"${FAKE_HVIGOR}" <<'FAKE_HVIGOR_SCRIPT'
#!/usr/bin/env bash
set -u

printf '%s\n' "$*" >>"${FAKE_HVIGOR_LOG}"
if [[ "${1:-}" == "--version" ]]; then
  printf '%s\n' "${FAKE_HVIGOR_VERSION:-6.24.2}"
  exit 0
fi
if [[ "$*" == *"assembleHap"* && -n "${FAKE_ENTRY_OUTPUT:-}" ]]; then
  mkdir -p "$(dirname "${FAKE_ENTRY_OUTPUT}")"
  printf 'fresh-entry-hap\n' >"${FAKE_ENTRY_OUTPUT}"
fi
if [[ "$*" == *"genOnDeviceTestHap"* && -n "${FAKE_TEST_OUTPUT:-}" ]]; then
  mkdir -p "$(dirname "${FAKE_TEST_OUTPUT}")"
  printf 'fresh-test-hap\n' >"${FAKE_TEST_OUTPUT}"
fi
exit 0
FAKE_HVIGOR_SCRIPT

  cat >"${FAKE_GIT}" <<'FAKE_GIT_SCRIPT'
#!/usr/bin/env bash
set -u

if [[ "$*" == *" rev-parse HEAD" ]]; then
  printf '%s\n' "${FAKE_GIT_COMMIT:-0123456789abcdef0123456789abcdef01234567}"
  exit 0
fi
if [[ "$*" == *" status --porcelain" ]]; then
  printf '%b' "${FAKE_GIT_STATUS:-}"
  exit 0
fi
printf 'Unexpected fake git command: %s\n' "$*" >&2
exit 2
FAKE_GIT_SCRIPT

  chmod +x "${FAKE_HDC}" "${FAKE_HVIGOR}" "${FAKE_GIT}"
  : >"${HDC_LOG}"
  : >"${HVIGOR_LOG}"
}

run_skip_build() {
  local targets="$1"
  local report="$2"
  local device_id="${3:-}"
  local test_exit="${4:-0}"
  local fail_match="${5:-}"
  local fail_exit="${6:-7}"

  set +e
  env \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=1 \
    DEVICE_ID="${device_id}" \
    ENTRY_HAP="${ENTRY_FIXTURE_HAP}" \
    TEST_HAP="${TEST_FIXTURE_HAP}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS="${targets}" \
    FAKE_REPORT="${report}" \
    FAKE_TEST_EXIT="${test_exit}" \
    FAKE_FAIL_MATCH="${fail_match}" \
    FAKE_FAIL_EXIT="${fail_exit}" \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e
}

assert_success() {
  [[ "${RUN_STATUS}" == "0" ]] || {
    cat "${RUN_OUTPUT_FILE}" >&2
    return 1
  }
}

assert_failure() {
  [[ "${RUN_STATUS}" != "0" ]] || {
    cat "${RUN_OUTPUT_FILE}" >&2
    return 1
  }
}

test_strict_success() {
  new_fixture strict-success
  run_skip_build $'device-a\n' "${PASS_REPORT}"
  assert_success || return 1
  grep -q '^HAR module UITest passed\.$' "${RUN_OUTPUT_FILE}" || return 1
}

test_report_failure_count() {
  new_fixture report-failure
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 1, Error: 0, Pass: 1, Ignore: 0\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_report_error_count() {
  new_fixture report-error
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 1, Pass: 1, Ignore: 0\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_report_ignore_count() {
  new_fixture report-ignore
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 1, Ignore: 1\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_report_pass_total_mismatch() {
  new_fixture report-mismatch
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 1, Ignore: 0\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_duplicate_result_rejected() {
  new_fixture duplicate-result
  run_skip_build $'device-a\n' \
    "${PASS_REPORT}"$'\nOHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0'
  assert_failure
}

test_missing_result_rejected() {
  new_fixture missing-result
  run_skip_build $'device-a\n' $'OHOS_REPORT_CODE: 0'
  assert_failure
}

test_nonzero_code_rejected() {
  new_fixture nonzero-code
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0\nOHOS_REPORT_CODE: -1'
  assert_failure
}

test_duplicate_code_rejected() {
  new_fixture duplicate-code
  run_skip_build $'device-a\n' "${PASS_REPORT}"$'\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_missing_code_rejected() {
  new_fixture missing-code
  run_skip_build $'device-a\n' \
    $'OHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0'
  assert_failure
}

test_hdc_failure_marker_rejected() {
  new_fixture hdc-marker
  run_skip_build $'device-a\n' \
    $'[Fail][E005003] synthetic transport failure\nOHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_generic_hdc_failure_marker_rejected() {
  new_fixture hdc-generic-marker
  run_skip_build $'device-a\n' \
    $'[Fail]Not match target founded, check connect-key please.\nOHOS_REPORT_RESULT: stream=Tests run: 2, Failure: 0, Error: 0, Pass: 2, Ignore: 0\nOHOS_REPORT_CODE: 0'
  assert_failure
}

test_hdc_nonzero_rejected() {
  new_fixture hdc-nonzero
  run_skip_build $'device-a\n' "${PASS_REPORT}" "" 19
  assert_failure
}

test_zero_devices_rejected() {
  new_fixture zero-devices
  run_skip_build "" "${PASS_REPORT}"
  assert_failure || return 1
  grep -q 'No HDC target is connected' "${RUN_OUTPUT_FILE}" || return 1
}

test_list_targets_generic_failure_rejected() {
  new_fixture list-targets-generic-failure
  run_skip_build $'[Fail]No any connected target\n' "${PASS_REPORT}"
  assert_failure || return 1
  grep -q 'HDC reported a failure marker' "${RUN_OUTPUT_FILE}" || return 1
}

test_multiple_devices_require_device_id() {
  new_fixture multiple-devices
  run_skip_build $'device-a\ndevice-b\n' "${PASS_REPORT}"
  assert_failure || return 1
  grep -q 'Multiple HDC targets are connected' "${RUN_OUTPUT_FILE}" || return 1
}

test_unknown_device_id_rejected() {
  new_fixture unknown-device
  run_skip_build $'device-a\ndevice-b\n' "${PASS_REPORT}" device-c
  assert_failure || return 1
  grep -q 'DEVICE_ID is not connected' "${RUN_OUTPUT_FILE}" || return 1
}

test_every_device_operation_is_scoped() {
  new_fixture scoped-device
  run_skip_build $'device-a\ndevice-b\n' "${PASS_REPORT}" device-b
  assert_success || return 1

  local line
  while IFS= read -r line; do
    [[ "${line}" == "list targets" ]] && continue
    [[ "${line}" == "-t device-b "* ]] || {
      printf 'Unscoped HDC command: %s\n' "${line}" >&2
      return 1
    }
  done <"${HDC_LOG}"
  grep -q '^-t device-b uninstall ' "${HDC_LOG}" || return 1
  grep -q '^-t device-b shell bm install ' "${HDC_LOG}" || return 1
  grep -q '^-t device-b shell aa test ' "${HDC_LOG}" || return 1
}

test_trap_cleanup_is_scoped() {
  new_fixture scoped-cleanup
  run_skip_build $'device-a\n' "${PASS_REPORT}" device-a 0 'file send' 7
  assert_failure || return 1
  grep -Eq '^-t device-a shell rm -rf /data/local/tmp/har_uitest_' \
    "${HDC_LOG}" || return 1
}

test_skip_build_warns_not_acceptance_evidence() {
  new_fixture skip-warning
  run_skip_build $'device-a\n' "${PASS_REPORT}"
  assert_success || return 1
  grep -q 'SKIP_BUILD=1 is for local debugging only' \
    "${RUN_OUTPUT_FILE}" || return 1
  grep -q 'cannot be used as acceptance evidence' \
    "${RUN_OUTPUT_FILE}" || return 1
}

test_build_mode_preserves_custom_haps() {
  new_fixture preserve-custom

  set +e
  env \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=0 \
    DEVICE_ID=device-a \
    ENTRY_HAP="${ENTRY_FIXTURE_HAP}" \
    TEST_HAP="${TEST_FIXTURE_HAP}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS=$'device-a\n' \
    FAKE_REPORT="${PASS_REPORT}" \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e

  assert_failure || return 1
  grep -q 'ENTRY_HAP and TEST_HAP cannot be overridden when SKIP_BUILD=0' \
    "${RUN_OUTPUT_FILE}" || return 1
  grep -q '^entry-hap$' "${ENTRY_FIXTURE_HAP}" || return 1
  grep -q '^test-hap$' "${TEST_FIXTURE_HAP}" || return 1
  [[ ! -s "${HVIGOR_LOG}" ]] || return 1
}

test_build_mode_rejects_absolute_module_path_outside_project() {
  new_fixture reject-absolute-module-path

  local suffix="$$-${RANDOM}"
  local entry_module="haruitestentry${suffix}"
  local outside_module_dir="${TEST_ROOT}/outside-module-${suffix}"
  local canary="${outside_module_dir}/build/default/outputs/ohosTest/main-ohosTest-unsigned.hap"
  mkdir -p \
    "${PROJECT_ROOT}/${entry_module}" \
    "$(dirname "${canary}")"
  printf 'outside-canary\n' >"${canary}"
  GENERATED_PROJECT_DIRS+=(
    "${PROJECT_ROOT}/${entry_module}"
    "${outside_module_dir}"
  )

  set +e
  env \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=0 \
    DEVICE_ID=127.0.0.1:5555 \
    ENTRY_MODULE="${entry_module}" \
    HAR_MODULE_DIR="${outside_module_dir}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS=$'127.0.0.1:5555\n' \
    FAKE_REPORT="${PASS_REPORT}" \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e

  assert_failure || return 1
  grep -q '^outside-canary$' "${canary}" || return 1
  [[ ! -s "${HVIGOR_LOG}" ]] || return 1
}

test_build_mode_rejects_parent_module_path_outside_project() {
  new_fixture reject-parent-module-path

  local suffix="$$-${RANDOM}"
  local entry_module="haruitestentry${suffix}"
  local outside_name="haruitest-outside-${suffix}"
  local outside_module_dir="${PROJECT_ROOT}/../${outside_name}"
  local canary="${outside_module_dir}/build/default/outputs/ohosTest/main-ohosTest-unsigned.hap"
  mkdir -p \
    "${PROJECT_ROOT}/${entry_module}" \
    "$(dirname "${canary}")"
  printf 'outside-canary\n' >"${canary}"
  GENERATED_PROJECT_DIRS+=(
    "${PROJECT_ROOT}/${entry_module}"
    "${outside_module_dir}"
  )

  set +e
  env \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=0 \
    DEVICE_ID=127.0.0.1:5555 \
    ENTRY_MODULE="${entry_module}" \
    HAR_MODULE_DIR="../${outside_name}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS=$'127.0.0.1:5555\n' \
    FAKE_REPORT="${PASS_REPORT}" \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e

  assert_failure || return 1
  grep -q '^outside-canary$' "${canary}" || return 1
  [[ ! -s "${HVIGOR_LOG}" ]] || return 1
}

test_build_mode_accepts_repository_module_path_with_spaces() {
  new_fixture accept-module-path-spaces

  local suffix="$$-${RANDOM}"
  local entry_module="haruitestentry${suffix}"
  local har_module_dir="har uitest feature ${suffix}"
  local entry_output="${PROJECT_ROOT}/${entry_module}/build/default/outputs/default/${entry_module}-default-unsigned.hap"
  local test_output="${PROJECT_ROOT}/${har_module_dir}/build/default/outputs/ohosTest/main-ohosTest-unsigned.hap"
  mkdir -p \
    "${PROJECT_ROOT}/${entry_module}" \
    "${PROJECT_ROOT}/${har_module_dir}"
  GENERATED_PROJECT_DIRS+=(
    "${PROJECT_ROOT}/${entry_module}"
    "${PROJECT_ROOT}/${har_module_dir}"
  )

  set +e
  env \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=0 \
    DEVICE_ID=127.0.0.1:5555 \
    ENTRY_MODULE="${entry_module}" \
    HAR_MODULE_DIR="${har_module_dir}" \
    FAKE_ENTRY_OUTPUT="${entry_output}" \
    FAKE_TEST_OUTPUT="${test_output}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS=$'127.0.0.1:5555\n' \
    FAKE_REPORT="${PASS_REPORT}" \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e

  assert_success
}

test_non_skip_evidence_is_traceable_and_redacted() {
  new_fixture evidence

  local suffix="$$-${RANDOM}"
  local entry_module="haruitestentry${suffix}"
  local har_module_dir="haruitestfeature${suffix}"
  local entry_output="${PROJECT_ROOT}/${entry_module}/build/default/outputs/default/${entry_module}-default-unsigned.hap"
  local test_output="${PROJECT_ROOT}/${har_module_dir}/build/default/outputs/ohosTest/main-ohosTest-unsigned.hap"
  local evidence_file="${FIXTURE}/device-evidence.md"
  mkdir -p \
    "${PROJECT_ROOT}/${entry_module}" \
    "${PROJECT_ROOT}/${har_module_dir}"
  GENERATED_PROJECT_DIRS+=(
    "${PROJECT_ROOT}/${entry_module}"
    "${PROJECT_ROOT}/${har_module_dir}"
  )

  set +e
  env \
    PATH="${FAKE_BIN_DIR}:${PATH}" \
    HDC="${FAKE_HDC}" \
    HVIGORW="${FAKE_HVIGOR}" \
    SKIP_BUILD=0 \
    DEVICE_ID=127.0.0.1:5555 \
    ENTRY_MODULE="${entry_module}" \
    HAR_MODULE_DIR="${har_module_dir}" \
    EVIDENCE_FILE="${evidence_file}" \
    FAKE_ENTRY_OUTPUT="${entry_output}" \
    FAKE_TEST_OUTPUT="${test_output}" \
    FAKE_HDC_LOG="${HDC_LOG}" \
    FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
    FAKE_TARGETS=$'127.0.0.1:5555\n' \
    FAKE_REPORT="${PASS_REPORT}" \
    FAKE_OS_VERSION=OpenHarmony-5.0.5.310 \
    FAKE_API_VERSION=18 \
    FAKE_GIT_COMMIT=0123456789abcdef0123456789abcdef01234567 \
    FAKE_GIT_STATUS= \
    bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
  RUN_STATUS=$?
  set -e

  assert_success || return 1
  [[ -f "${evidence_file}" ]] || return 1
  grep -q '^target_commit: 0123456789abcdef0123456789abcdef01234567$' \
    "${evidence_file}" || return 1
  grep -q '^target_worktree_clean: true$' "${evidence_file}" || return 1
  grep -q '^device_connect_key_sha256: [0-9a-f]\{64\}$' \
    "${evidence_file}" || return 1
  grep -q '^device_os_version: OpenHarmony-5.0.5.310$' \
    "${evidence_file}" || return 1
  grep -q '^device_api_version: 18$' "${evidence_file}" || return 1
  grep -q '^hvigor_version: 6.24.2$' "${evidence_file}" || return 1
  grep -q '^skip_build: 0$' "${evidence_file}" || return 1
  grep -q '^acceptance_eligible: true$' "${evidence_file}" || return 1
  grep -q '^hap_signing_status: unsigned-emulator$' \
    "${evidence_file}" || return 1
  grep -q '^entry_hap_sha256: [0-9a-f]\{64\}$' \
    "${evidence_file}" || return 1
  grep -q '^test_hap_sha256: [0-9a-f]\{64\}$' \
    "${evidence_file}" || return 1
  grep -Fq "final_result: ${PASS_REPORT%%$'\n'*}" \
    "${evidence_file}" || return 1
  grep -q '^final_code: OHOS_REPORT_CODE: 0$' \
    "${evidence_file}" || return 1
  grep -q '^test_shell_exit_status: 0$' "${evidence_file}" || return 1
  grep -q '^test_command: hdc -t <sha256:' "${evidence_file}" || return 1
  ! grep -q '127.0.0.1:5555' "${evidence_file}" || return 1
}

test_dirty_worktree_cannot_create_acceptance_evidence() {
  new_fixture dirty-evidence

  local suffix="$$-${RANDOM}"
  local entry_module="haruitestentry${suffix}"
  local har_module_dir="haruitestfeature${suffix}"
  local evidence_file="${FIXTURE}/device-evidence.md"
  local dirty_status
  mkdir -p \
    "${PROJECT_ROOT}/${entry_module}" \
    "${PROJECT_ROOT}/${har_module_dir}"
  GENERATED_PROJECT_DIRS+=(
    "${PROJECT_ROOT}/${entry_module}"
    "${PROJECT_ROOT}/${har_module_dir}"
  )

  for dirty_status in $' M README.md\n' $'?? local.txt\n'; do
    : >"${HDC_LOG}"
    : >"${HVIGOR_LOG}"
    rm -f "${evidence_file}"
    set +e
    env \
      PATH="${FAKE_BIN_DIR}:${PATH}" \
      HDC="${FAKE_HDC}" \
      HVIGORW="${FAKE_HVIGOR}" \
      SKIP_BUILD=0 \
      DEVICE_ID=127.0.0.1:5555 \
      ENTRY_MODULE="${entry_module}" \
      HAR_MODULE_DIR="${har_module_dir}" \
      EVIDENCE_FILE="${evidence_file}" \
      FAKE_HDC_LOG="${HDC_LOG}" \
      FAKE_HVIGOR_LOG="${HVIGOR_LOG}" \
      FAKE_TARGETS=$'127.0.0.1:5555\n' \
      FAKE_REPORT="${PASS_REPORT}" \
      FAKE_GIT_COMMIT=0123456789abcdef0123456789abcdef01234567 \
      FAKE_GIT_STATUS="${dirty_status}" \
      bash "${RUNNER}" >"${RUN_OUTPUT_FILE}" 2>&1
    RUN_STATUS=$?
    set -e

    assert_failure || return 1
    [[ ! -e "${evidence_file}" ]] || return 1
    [[ ! -s "${HDC_LOG}" ]] || return 1
    [[ ! -s "${HVIGOR_LOG}" ]] || return 1
  done
}

run_test() {
  local name="$1"
  local test_function="$2"
  if "${test_function}"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'ok - %s\n' "${name}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf 'not ok - %s\n' "${name}" >&2
  fi
}

run_test 'accepts one exact passing report' test_strict_success
run_test 'rejects Failure > 0' test_report_failure_count
run_test 'rejects Error > 0' test_report_error_count
run_test 'rejects Ignore > 0' test_report_ignore_count
run_test 'rejects Pass/Tests run mismatch' test_report_pass_total_mismatch
run_test 'rejects duplicate result reports' test_duplicate_result_rejected
run_test 'rejects missing result report' test_missing_result_rejected
run_test 'rejects non-zero report code' test_nonzero_code_rejected
run_test 'rejects duplicate report code' test_duplicate_code_rejected
run_test 'rejects missing report code' test_missing_code_rejected
run_test 'rejects HDC failure marker with zero exit' test_hdc_failure_marker_rejected
run_test 'rejects generic HDC failure marker with zero exit' test_generic_hdc_failure_marker_rejected
run_test 'rejects non-zero HDC shell status' test_hdc_nonzero_rejected
run_test 'rejects zero connected devices' test_zero_devices_rejected
run_test 'rejects generic HDC failure while listing targets' test_list_targets_generic_failure_rejected
run_test 'requires DEVICE_ID for multiple devices' test_multiple_devices_require_device_id
run_test 'rejects unknown DEVICE_ID' test_unknown_device_id_rejected
run_test 'scopes all HDC operations to one device' test_every_device_operation_is_scoped
run_test 'scopes trap cleanup to the same device' test_trap_cleanup_is_scoped
run_test 'marks SKIP_BUILD as debug-only' test_skip_build_warns_not_acceptance_evidence
run_test 'preserves custom HAPs in build mode' test_build_mode_preserves_custom_haps
run_test 'rejects absolute module cleanup path outside project' test_build_mode_rejects_absolute_module_path_outside_project
run_test 'rejects parent module cleanup path outside project' test_build_mode_rejects_parent_module_path_outside_project
run_test 'accepts repository module path with spaces' test_build_mode_accepts_repository_module_path_with_spaces
run_test 'writes traceable redacted non-skip evidence' test_non_skip_evidence_is_traceable_and_redacted
run_test 'rejects acceptance evidence from a dirty worktree' test_dirty_worktree_cannot_create_acceptance_evidence

printf '%d passed, %d failed\n' "${PASS_COUNT}" "${FAIL_COUNT}"
[[ "${FAIL_COUNT}" == "0" ]]
