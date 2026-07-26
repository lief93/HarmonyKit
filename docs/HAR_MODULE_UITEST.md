# 在业务 HAR 中编写并运行 UITest

## 结论

业务 HAR 可以把 Hypium/TestKit UITest 放在自己的 `src/ohosTest` 中。本项目的测试位于
`feature/main/src/ohosTest`，编译、打包和设备执行都已验证。

需要区分两个边界：

1. HAR 自己的测试组件或测试页面，可由 HAR 生成的测试 HAP 独立驱动。
2. 如果测试要启动真实应用的 `entry/EntryAbility`，设备上必须同时安装 entry HAP 和
   HAR 测试 HAP。HAR 本身不是可安装的 HAP，不能代替 entry。

因此，`assembleHar` 只能证明 HAR 库产物可构建，不能证明 UITest 可运行。HAR UITest 的
打包门禁是 `genOnDeviceTestHap`，设备执行门禁是测试 HAP 被安装后运行 `aa test`。

## 本项目的结构

```text
feature/main/
├── build-profile.json5
└── src/
    ├── main/                         # 真实业务页面与逻辑
    └── ohosTest/
        ├── module.json5              # type: feature 的测试 HAP
        └── ets/test/
            ├── List.test.ets
            └── Ability.test.ets      # Hypium + TestKit Driver
```

`feature/main/build-profile.json5` 声明了 `ohosTest` target。测试 HAP 的
`module.json5` 使用 `type: "feature"`；生产模块仍然是 HAR，没有改成 HAP。

## 一键运行真实 App 流程

先确认 HDC 目标：

```bash
hdc list targets
```

只有一个目标时脚本会自动选择。存在多个设备或模拟器时，必须把目标的完整 connect key
通过 `DEVICE_ID` 明确传入；未指定时脚本拒绝执行，避免卸载或安装到其他设备。

物理设备或远程设备需要在 DevEco Studio 中配置调试签名。仓库不包含证书、profile、
密钥库或密码。明确选择的 loopback 模拟器（例如 `127.0.0.1:5555`）可以安装本轮刚构建
的 unsigned HAP，证据会明确标记为 `unsigned-emulator`，不能泛化到物理设备。

连接设备或模拟器后执行：

```bash
DEVICE_ID=127.0.0.1:5555 ./scripts/run-har-uitest.sh
```

脚本执行以下门禁：

1. 解析 `hdc list targets`，选出唯一 connect key。
2. 只删除脚本计算出的仓库内默认 signed/unsigned HAP，随后重新构建 entry HAP。
3. 对业务 HAR 执行 `genOnDeviceTestHap`，重新生成测试 HAP。
4. 所有卸载、传输、安装、`aa test` 和 trap 清理都使用同一
   `hdc -t <connectkey>`。
5. 使用 `bm install -p` 一次性安装 entry HAP 与 HAR 测试 HAP。
6. 使用 `aa test` 运行 HAR 内的 Hypium 测试。
7. 拒绝 HDC failure marker，并且只接受唯一、格式精确的最终报告：
   `Tests run == Pass > 0`，`Failure/Error/Ignore == 0`，同时只能存在一行精确的
   `OHOS_REPORT_CODE: 0`。

可选环境变量：

```bash
HVIGORW=/path/to/hvigorw \
HDC=/path/to/hdc \
DEVICE_ID=127.0.0.1:5555 \
TEST_SCOPE=MainHarUiTest \
./scripts/run-har-uitest.sh
```

`SKIP_BUILD=1` 只用于本地诊断预生成 HAP，不能作为提交验收、Review 通过或 CI
证据。该模式会输出明确 warning，并禁止写 `EVIDENCE_FILE`：

```bash
SKIP_BUILD=1 \
DEVICE_ID=127.0.0.1:5555 \
ENTRY_HAP=/absolute/path/to/entry.hap \
TEST_HAP=/absolute/path/to/main-test.hap \
./scripts/run-har-uitest.sh
```

其他可覆盖项包括 `PRODUCT`、`BUILD_MODE`、`ENTRY_MODULE`、`ENTRY_TARGET`、
`HAR_MODULE_NAME`、`HAR_MODULE_DIR`、`BUNDLE_NAME`、`TEST_MODULE_NAME`、
`TEST_TIMEOUT_MS`。`ENTRY_HAP` 和 `TEST_HAP` 仅能在 `SKIP_BUILD=1` 使用；
正常构建模式如果发现这两个覆盖项会在执行构建或删除文件前失败。

## 生成提交验收证据

验收证据必须使用正常构建模式，并从干净、已提交的目标 revision 执行：

```bash
DEVICE_ID=127.0.0.1:5555 \
EVIDENCE_FILE=docs/evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md \
./scripts/run-har-uitest.sh
```

证据文件包含：

- 目标 Git commit 和执行前工作区是否干净；
- 完整的 build/test 参数、bundle 和 module 元数据；
- connect key 的 SHA-256（不写入原始设备标识）、设备类型、OS 和 API；
- DevEco Studio 与 Hvigor 版本；
- entry/test HAP 的路径、字节数和 SHA-256；
- 唯一最终 `OHOS_REPORT_RESULT`、`OHOS_REPORT_CODE`；
- HDC `aa test` shell 退出码和脚本退出码。

只有文件中的 `skip_build: 0`、`acceptance_eligible: true` 才能用于验收。证据绑定的
`target_commit` 是实际构建与设备执行的代码提交；把证据文件加入后续提交不会反向改变
已执行代码的 commit。

合成负向测试不连接真实设备，可独立验证报告和设备选择门禁：

```bash
bash scripts/tests/run-har-uitest.test.sh
```

## 单独生成 HAR 测试 HAP

```bash
hvigorw genOnDeviceTestHap \
  --mode module \
  -p module=main@ohosTest \
  -p product=default \
  -p buildMode=test \
  -p isOhosTest=true \
  --no-daemon
```

预期产物：

```text
feature/main/build/default/outputs/ohosTest/main-ohosTest-signed.hap
```

没有配置签名时只能得到 `main-ohosTest-unsigned.hap`，它不能直接完成设备测试。

## 为什么不直接依赖 HAR 的原生 `onDeviceTest`

当前验证使用的 DevEco/Hvigor 版本中，HAR 执行原生 `onDeviceTest` 时会先卸载目标 bundle。
执行器只把 `.hap` 和 `.hsp` 加入安装集合，HAR 的默认目标产物是 `.har`，因此最终只安装
HAR 测试 HAP。此时 `aa test` 本身可以启动，但测试中显式启动 `entry/EntryAbility` 会失败，
因为 entry 已被卸载。

这不是“HAR 不能写 UITest”，而是“跨真实 App 的 HAR 测试需要多 HAP 安装”。本项目脚本
保留标准 `genOnDeviceTestHap` 产物，并显式完成 entry HAP + 测试 HAP 的正确安装关系。

还要注意：Hvigor 的任务进程可能在用例失败时仍打印 `BUILD SUCCESSFUL`。判断设备测试
是否通过，必须同时检查 HDC shell 退出码、唯一严格
`OHOS_REPORT_RESULT`、唯一 `OHOS_REPORT_CODE: 0` 和 HDC failure marker。

## 已覆盖场景

`Ability.test.ets` 当前覆盖：

- 显式启动真实 `EntryAbility`，进入 HAR 提供的业务主页面。
- 每个用例之间终止并重新创建 Ability，验证页面与导航栈隔离。
- 通过资源 key 获取文案 value，再用 Driver 查找控件。
- Tab 切换、点击、滚动查找、系统返回与输入框输入。
- 直接调用业务 Navigator 打开目标页面。
- 带参导航和结果回传。
- Mock repository 返回值。
- Deferred Promise 严格验证 Loading → 成功态切换。
- 状态页、安全区、屏幕适配和本地存储。

修复后的可追溯设备验证：

```text
Tests run: 12, Failure: 0, Error: 0, Pass: 12, Ignore: 0
```

证据见
[`evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md`](evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md)。
它由正常构建模式生成，绑定代码提交
`63d8ed2fe8293c123cc7dec5e02142c514c613b1`，设备 connect key 只保留 SHA-256。
自动化结果证明测试执行和断言通过，不替代人工视觉还原验收。
