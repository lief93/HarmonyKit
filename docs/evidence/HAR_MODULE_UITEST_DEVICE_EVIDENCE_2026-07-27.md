# HAR module UITest device evidence

schema: harmony-kit.har-uitest-device-evidence.v1
recorded_at_utc: 2026-07-26T16:44:43Z
target_commit: 63d8ed2fe8293c123cc7dec5e02142c514c613b1
target_worktree_clean: true
runner: scripts/run-har-uitest.sh
skip_build: 0
acceptance_eligible: true
hap_signing_status: unsigned-emulator
product: default
build_mode: test
entry_module: entry
entry_target: default
har_module_name: main
har_module_dir: feature/main
bundle_name: com.joker.kit
test_module_name: main_test
test_scope: <all>
test_timeout_ms: 15000
device_kind: emulator
device_connect_key_sha256: 6460677a198b1872315bae7231fb6131092f3569882742677a6ee620177b668b
device_os_version: OpenHarmony-6.1.1.125
device_api_version: 24
deveco_version: 6.1.1
deveco_sdk_home: /Applications/DevEco-Studio.app/Contents/sdk
hvigor_version: 6.24.2
entry_build_command: /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p module=entry@default -p product=default -p buildMode=test --no-daemon
test_build_command: /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw genOnDeviceTestHap --mode module -p module=main@ohosTest -p product=default -p buildMode=test -p isOhosTest=true --no-daemon
test_command: hdc -t <sha256:6460677a198b1872315bae7231fb6131092f3569882742677a6ee620177b668b> shell aa test -b com.joker.kit -m main_test -s unittest /ets/testrunner/OpenHarmonyTestRunner -s timeout 15000 -s coverage false
entry_hap_path: entry/build/default/outputs/default/entry-default-unsigned.hap
entry_hap_bytes: 4393234
entry_hap_sha256: 6d845d14153640af1604282efdccccb380b52e82f8f36f45f5781a9a0eea722e
test_hap_path: feature/main/build/default/outputs/ohosTest/main-ohosTest-unsigned.hap
test_hap_bytes: 4487493
test_hap_sha256: 5c7eb7fd23208f79233750abfa748e887bf49682b57db8e6468136d4ab9e287b
final_result: OHOS_REPORT_RESULT: stream=Tests run: 12, Failure: 0, Error: 0, Pass: 12, Ignore: 0
final_code: OHOS_REPORT_CODE: 0
test_shell_exit_status: 0
script_exit_status: 0
