#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
UITEST="${PROJECT_ROOT}/uitest"
TEST_ROOT="$(mktemp -d -t uitest-entry-tests.XXXXXX)"

cleanup() {
  rm -rf "${TEST_ROOT}"
}
trap cleanup EXIT

FAKE_HDC="${TEST_ROOT}/hdc"
FAKE_HVIGOR="${TEST_ROOT}/hvigorw"
ENTRY_HAP="${TEST_ROOT}/entry.hap"
TEST_HAP="${TEST_ROOT}/test.hap"
HDC_LOG="${TEST_ROOT}/hdc.log"
ENV_LOG="${TEST_ROOT}/env.log"
FAKE_DEVECO_HOME="${TEST_ROOT}/DevEco"

printf 'entry\n' >"${ENTRY_HAP}"
printf 'test\n' >"${TEST_HAP}"
mkdir -p "${FAKE_DEVECO_HOME}/tools/node/bin"
: >"${FAKE_DEVECO_HOME}/tools/node/bin/node"
chmod +x "${FAKE_DEVECO_HOME}/tools/node/bin/node"

cat >"${FAKE_HDC}" <<'FAKE_HDC_SCRIPT'
#!/usr/bin/env bash
set -u

printf '%s\n' "$*" >>"${FAKE_HDC_LOG}"
printf 'NODE_HOME=%s\n' "${NODE_HOME:-}" >>"${FAKE_ENV_LOG}"
if [[ "$*" == "list targets" ]]; then
  printf 'device-a\n'
elif [[ " $* " == *" shell aa test "* ]]; then
  printf '%s\n' \
    'OHOS_REPORT_RESULT: stream=Tests run: 1, Failure: 0, Error: 0, Pass: 1, Ignore: 0' \
    'OHOS_REPORT_CODE: 0'
fi
FAKE_HDC_SCRIPT

cat >"${FAKE_HVIGOR}" <<'FAKE_HVIGOR_SCRIPT'
#!/usr/bin/env bash
exit 0
FAKE_HVIGOR_SCRIPT
chmod +x "${FAKE_HDC}" "${FAKE_HVIGOR}"

FAKE_HDC_LOG="${HDC_LOG}" \
FAKE_ENV_LOG="${ENV_LOG}" \
HDC="${FAKE_HDC}" \
HVIGORW="${FAKE_HVIGOR}" \
DEVECO_STUDIO_HOME="${FAKE_DEVECO_HOME}" \
SKIP_BUILD=1 \
ENTRY_HAP="${ENTRY_HAP}" \
TEST_HAP="${TEST_HAP}" \
"${UITEST}" 'MainHarUiTest#launchShowsMainPage' >/dev/null

grep -Fq \
  'shell aa test -b com.joker.kit -m main_test -s unittest /ets/testrunner/OpenHarmonyTestRunner -s class MainHarUiTest#launchShowsMainPage -s timeout 60000 -s coverage false' \
  "${HDC_LOG}"
grep -Fxq "NODE_HOME=${FAKE_DEVECO_HOME}/tools/node" "${ENV_LOG}"

printf 'ok - one selector maps to class scope and 60000ms timeout\n'

assert_usage_failure() {
  local name="$1"
  shift
  local output_file="${TEST_ROOT}/${name}.log"
  local status

  set +e
  "$@" >"${output_file}" 2>&1
  status=$?
  set -e

  [[ "${status}" == "2" ]]
  grep -Fxq 'Usage: ./uitest ClassName[#testName]' "${output_file}"
  printf 'ok - %s\n' "${name}"
}

assert_usage_failure 'rejects zero selectors' "${UITEST}"
assert_usage_failure 'rejects multiple selectors' \
  "${UITEST}" MainHarUiTest OtherHarUiTest
assert_usage_failure 'rejects malformed selector' \
  "${UITEST}" 'MainHarUiTest # launchShowsMainPage'
