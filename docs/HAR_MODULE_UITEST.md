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

先在 DevEco Studio 中为当前设备配置调试签名。仓库不包含证书、profile、密钥库或密码。

连接设备或模拟器后执行：

```bash
./scripts/run-har-uitest.sh
```

脚本执行以下门禁：

1. 构建并签名真实 entry HAP。
2. 对业务 HAR 执行 `genOnDeviceTestHap`，生成并签名测试 HAP。
3. 卸载同 bundle 的旧安装。
4. 使用 `bm install -p` 一次性安装 entry HAP 与 HAR 测试 HAP。
5. 使用 `aa test` 运行 HAR 内的 Hypium 测试。
6. 解析 `OHOS_REPORT_RESULT` 和 `OHOS_REPORT_CODE`；存在 Failure/Error 或没有测试结果时返回非零状态。

可选环境变量：

```bash
HVIGORW=/path/to/hvigorw \
HDC=/path/to/hdc \
TEST_SCOPE=MainHarUiTest \
./scripts/run-har-uitest.sh
```

已提前生成签名 HAP 时，可以跳过构建：

```bash
SKIP_BUILD=1 ./scripts/run-har-uitest.sh
```

其他可覆盖项包括 `PRODUCT`、`BUILD_MODE`、`ENTRY_MODULE`、`ENTRY_TARGET`、
`HAR_MODULE_NAME`、`HAR_MODULE_DIR`、`BUNDLE_NAME`、`TEST_MODULE_NAME`、
`TEST_TIMEOUT_MS`、`ENTRY_HAP` 和 `TEST_HAP`。

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

还要注意：Hvigor 的任务进程可能在用例失败时仍打印 `BUILD SUCCESSFUL`。判断设备测试是否
通过，应读取 `OHOS_REPORT_RESULT`，不能只检查构建进程退出码。

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

本地设备验证结果：

```text
Tests run: 12, Failure: 0, Error: 0, Pass: 12, Ignore: 0
```

自动化结果证明测试执行和断言通过，不替代人工视觉还原验收。
