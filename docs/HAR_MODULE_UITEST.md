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
            ├── framework/            # 可复用的 Driver/异步测试基础能力
            ├── support/              # 项目适配、fixture 与宿主生命周期
            ├── robots/               # 页面操作和页面断言
            ├── specs/                # Hypium 业务测试语义
            ├── Ability.test.ets      # 只组合 MainHarUiTest 测试套
            └── List.test.ets          # 测试入口
```

`feature/main/build-profile.json5` 声明了 `ohosTest` target。测试 HAP 的
`module.json5` 使用 `type: "feature"`；生产模块仍然是 HAR，没有改成 HAP。

这套目录是可运行的参考结构，不代表已经发布了一套测试 SDK：

- `framework` 只放与 HarmonyKit 业务无关、未来可能提取成 SDK 的通用能力，例如
  Driver 查找/点击/滚动封装和 Deferred。
- `support` 负责 bundle、EntryAbility、导航栈隔离、资源文案、业务模型和 fixture，迁移到
  其他项目时需要替换。
- `robots` 把 Driver 细节组织成页面级操作与断言，不注册 Hypium 用例。
- `specs` 表达业务流程、Mock 生命周期和测试数据，并保留稳定的用例名称。
- `Ability.test.ets` 只负责在唯一的 `MainHarUiTest` suite 中注册各组 specs，因此
  `MainHarUiTest#testName` 的命令行与 IDE 选择器保持不变。

## 不经过生产路由，直接挂载业务组件

鸿蒙 UITest 不只能够从 EntryAbility 沿生产路由进入页面。本项目还提供了一个接近
Compose UI Test `setContent` 的设备测试示例：

```bash
./uitest 'MainHarUiTest#mountsBusinessComponentIntoTestWindowWithoutRoute'
```

该用例取得 HAR 测试 HAP 自动生成的 `TestAbility` 及其窗口，通过
`ComponentContent` 和 `OverlayManager.addComponentContent`，把真实生产组件
`BaseNetWorkView` 直接挂到测试窗口。测试控制一个仅存在于 `ohosTest` 的宿主状态，使用
Driver 验证 Loading、点击切换到 Success，以及卸载后的窗口恢复。它不启动生产
`EntryAbility`，不调用业务 Navigator，也不创建生产 `NavPathStack` 记录。

相关文件职责：

- `framework/ComponentMount.ets`：把任意无参数 `WrappedBuilder` 挂到当前测试窗口，并返回
  可卸载的句柄。
- `specs/DirectMount.spec.ets`：定义测试专用宿主、挂载真实业务组件并执行 Driver 断言。
- 每次挂载都必须在 `finally` 中调用 `unmount()`；它会先从 Overlay 移除内容，再
  `dispose()`，避免污染后续用例。

这个方式适合测试可独立渲染的页面内容、控件组合和注入后的 UI 状态。若一个生产页面的
根节点本身是 `NavDestination`，依赖生产 Navigation Provider、路由参数、返回栈或
EntryAbility 生命周期，就不能把这些依赖当作不存在；应直接挂载拆出的可复用页面内容，
或由测试宿主补齐所需上下文。生产路由、路由参数和 Ability 生命周期仍应保留真实 App
流程测试。

## 日常运行：只输入一个测试选择器

仓库根目录的 `uitest` 是日常单用例入口。它只接受一个参数，自动完成构建、唯一设备
选择、entry + HAR 测试 HAP 安装和严格报告校验，并把测试超时固定为 60 秒：

```bash
./uitest 'MainHarUiTest#opensNetworkPageAndReturns'
```

也可以只指定整个测试套：

```bash
./uitest MainHarUiTest
```

零参数、多个参数或不符合 `ClassName[#testName]` 的选择器会直接失败。只有一个 HDC
目标时会自动选择；多目标环境仍会拒绝执行，避免误操作其他设备。

当前一参数入口只承诺并实测 **macOS + Bash**。`uitest` 使用
`#!/usr/bin/env bash`，不支持直接从 Windows CMD、PowerShell 或未提供兼容 Bash 与
HarmonyOS 工具链的环境运行；Windows/Linux 适配不在本交付范围内。

Node 补齐行为严格如下：

- 已存在 `NODE_HOME` 时，`uitest` 保留原值。
- `NODE_HOME` 为空时，候选目录是
  `${DEVECO_STUDIO_HOME:-/Applications/DevEco-Studio.app/Contents}/tools/node`。
- 只有候选目录中的 `bin/node` 可执行时，`uitest` 才导出该 `NODE_HOME`。
- 候选 Node 不存在时，入口不会声称已补齐环境，而是把原环境交给底层 runner；Hvigor
  仍可能报 `NODE_HOME is not set and not 'node' command found in your path`。

因此默认零配置路径仅适用于 DevEco Studio 安装在
`/Applications/DevEco-Studio.app/Contents` 的 macOS 环境。

如果希望完全在 DevEco Studio 中操作，在
`Settings > Tools > External Tools` 新增 `UITest (60s)`：

```text
Program:           $ProjectFileDir$/uitest
Arguments:         $Prompt$
Working directory: $ProjectFileDir$
```

运行 `UITest (60s)` 后，DevEco 只弹出一个 `Enter parameters` 输入框；输入
`MainHarUiTest#testName` 即可。该 External Tool 与命令行共用同一个 `uitest`，没有
第二套构建或设备脚本。

External Tool 是 DevEco 的**本机用户级配置**，不属于仓库文件。DevEco Studio 6.1
实测配置保存在
`~/Library/Application Support/Huawei/DevEcoStudio6.1/tools/External Tools.xml`。
换机、重装 DevEco Studio、切换或重置 IDE profile 后，必须重新创建上述配置；仅复制
或拉取本仓库不会自动得到该菜单项。

DevEco 不在默认安装路径时，把 External Tool 改为以下固定配置，运行时仍只输入一个
`ClassName[#testName]`：

```text
Program:           /usr/bin/env
Arguments:         DEVECO_STUDIO_HOME="/absolute/path/to/DevEco-Studio.app/Contents" "$ProjectFileDir$/uitest" $Prompt$
Working directory: $ProjectFileDir$
```

`DEVECO_STUDIO_HOME` 应指向同时包含 `tools/node`、`tools/hvigor` 和 SDK 的 DevEco
`Contents` 目录。如果 Hvigor 与 HDC 已能从原环境定位，只需指定其他 Node，也可以使用：

```text
Program:           /usr/bin/env
Arguments:         NODE_HOME="/absolute/path/to/node-home" "$ProjectFileDir$/uitest" $Prompt$
Working directory: $ProjectFileDir$
```

这里的 `NODE_HOME` 必须包含可执行的 `bin/node`。这些环境值是 External Tool 的固定
配置，不是每次运行需要输入的参数；每次弹窗仍只填写测试选择器。

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
2. 校验模块输出目录确实位于仓库内，只删除脚本计算出的默认 signed/unsigned HAP，
   随后重新构建 entry HAP。
3. 对业务 HAR 执行 `genOnDeviceTestHap`，重新生成测试 HAP。
4. 所有卸载、传输、安装、`aa test` 和 trap 清理都使用同一
   `hdc -t <connectkey>`。
5. 使用 `bm install -p` 一次性安装 entry HAP 与 HAR 测试 HAP。
6. 使用 `aa test` 运行 HAR 内的 Hypium 测试。
7. 拒绝任何行首为 `[Fail]` 的 HDC failure marker，并且只接受唯一、格式精确的最终报告：
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
`ENTRY_MODULE` 和 `HAR_MODULE_DIR` 必须指向仓库内已有目录；绝对路径、包含 `..`
的越界路径和解析到仓库外的符号链接会在清理产物前被拒绝。仓库内带空格的目录仍受支持。

## 生成提交验收证据

验收证据必须使用正常构建模式，并从干净、已提交的目标 revision 执行：

```bash
DEVICE_ID=127.0.0.1:5555 \
EVIDENCE_FILE=docs/evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md \
./scripts/run-har-uitest.sh
```

请求 `EVIDENCE_FILE` 时，脚本会在构建和设备操作前检查 tracked 与 untracked 状态；
工作区不干净会直接失败，不会生成可验收证据。

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

没有配置签名时只能得到 `main-ohosTest-unsigned.hap`，它不能直接用于物理或远程设备；
前文明确选择的 loopback 模拟器例外仍然适用。

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

分层后的 `specs` 当前覆盖：

- 显式启动真实 `EntryAbility`，进入 HAR 提供的业务主页面。
- 每个用例之间终止并重新创建 Ability，验证页面与导航栈隔离。
- 通过资源 key 获取文案 value，再用 Driver 查找控件。
- Tab 切换、点击、滚动查找、系统返回与输入框输入。
- 直接调用业务 Navigator 打开目标页面。
- 带参导航和结果回传。
- Mock repository 返回值。
- Deferred Promise 严格验证 Loading → 成功态切换。
- Mock 传输失败、业务失败 → 重试成功、列表空态和列表成功态。
- MockKit 精确/类型/正则参数、动态动作、同步/异步失败、调用次数和方法恢复。
- 通过 ComponentContent 把真实业务组件直接挂到 TestAbility 窗口，验证 Loading →
  Success 和卸载清理，全程不经过生产路由。
- 状态页、安全区、屏幕适配和本地存储。

原 HAR module-local 结构提交的可追溯设备验证：

```text
Tests run: 12, Failure: 0, Error: 0, Pass: 12, Ignore: 0
```

证据见
[`evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md`](evidence/HAR_MODULE_UITEST_DEVICE_EVIDENCE_2026-07-27.md)。
它由正常构建模式生成，具体代码提交记录在文件的 `target_commit` 字段中，设备
connect key 只保留 SHA-256。
自动化结果证明测试执行和断言通过，不替代人工视觉还原验收。

在上述结构上扩展 Mock 示例后，当前工作树的完整设备回归为 25/25；Mock 场景索引与本次
验证结果、能力边界和逐场景代码索引记录在
[`UITEST_MOCK_GUIDE.md`](UITEST_MOCK_GUIDE.md)。历史证据文件仍只证明其 `target_commit`
对应的 12 个用例，不将它冒充为当前工作树证据。
