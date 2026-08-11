# Hypium 连续 UITest：状态隔离与 Runner 生命周期研究

> 研究日期：2026-08-11
> 资料范围：OpenHarmony 官方文档、OpenHarmony/arkXtest（Hypium）官方源码、OpenHarmony 官方公开 GitHub 示例工程。没有使用内部资料或把搜索结果摘要当作证据。

## 结论摘要

1. **多个 `it` 连续运行是 Hypium 的正常模型。** `TestRunner` 拉起一次 `TestAbility`，`TestAbility.onCreate()` 调用一次 `Hypium.hypiumTest(...)`；Hypium 随后在同一任务中串行遍历各 suite/spec，所有 spec 完成后才调用 `finishTest()`。
2. **Hypium 不会自动重置页面、导航、数据库或业务单例。** 框架只按顺序调用开发者注册的 `beforeEach`、case、`afterEach`。隔离策略必须由测试工程实现。
3. **没有一手证据支持“TestAbility 与 EntryAbility 应当分进程”。** 官方 UITest 示例没有为二者配置独立进程；Stage 模型默认同一 bundle 的 UIAbility 在同一主进程。UIAbility 的 `process` 配置还只在 PC/2in1 和 Tablet 上生效，因此不是手机测试的通用解法。
4. **同进程不等于 `EntryAbility.terminateSelf()` 必然安全。** 官方定义是“销毁 UIAbility 自身”，且进程要等进程内所有 Ability 都退出后才进入销毁流程；但本项目在 loopback 模拟器实测发现，上一条 UI 操作结束后立即销毁明确识别的 EntryAbility，会让 `aa test` 收到 `App died, code: -1`。销毁前增加 300ms safe point 后，同一组后续 case 可以全部执行。
5. **明确能终止整套测试的生命周期路径是 TestAbility 被销毁。** arkXtest 当前模板在 `TestAbility.onDestroy()` 中直接执行 `finishTest('TestAbility onDestory unexpectedly!', -2)`。任何误销毁 TestAbility、应用进程被 force-stop/崩溃、或其他提前调用 `finishTest()` 的路径，都会让后续 case 无法继续。
6. **case 超时本身不能解释默认配置下的整套 `Stopped`。** 当前 Hypium 源码把超时转成当前 spec 的 Error；suite 循环捕获后仍会进入下一 spec，除非设置了 `breakOnError=true`。但源码也显示：case 抛错/超时时，`afterEach` 会被跳过；而 timeout 只是 reject 外层 Promise，并不会取消仍在执行的 case 函数。超时 case 可能与下一条 case 并发操作 UI，这会造成状态污染或 `uitest-api does not allow calling concurrently`。
7. **DevEco 的 `Stopped` 标签没有在所查一手资料中找到唯一原因映射。** 不能仅凭这个 UI 状态断言是超时、进程退出或生命周期竞争；必须用 `finishTest` 消息、AbilityMonitor 生命周期和进程/崩溃日志复现取证。
8. **业务页面遗留的未处理回调可以在下一条 case 中终止整个测试进程。** 当前模拟器的业务侧红绿实验中，测试只正常进入页面、返回并继续操作；未清理的业务定时回调在页面退出后抛出未处理异常时，第 2 条 case 只有 start、没有 done，后续 case 不再启动，`aa test` 返回 `App died/-1`。业务提供正常的 `reset()`，并在页面退出生命周期中主动调用后，同流程 4/4 Pass。

## 1. 连续 case 是怎样调度的

官方公开 UITest 示例的启动链如下：

1. 自定义 `OpenHarmonyTestRunner.onRun()` 注册 TestAbility monitor，并通过 `aa start` 拉起一次 TestAbility。[官方示例 Runner](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/ets/TestRunner/OpenHarmonyTestRunner.ts#L30-L62)
2. `TestAbility.onCreate()` 调用一次 `Hypium.hypiumTest(..., testsuite)`。[官方示例 TestAbility](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/ets/testability/TestAbility.ets#L25-L34)
3. `List.test.ets` 在一个 `testsuite()` 中注册许多测试文件/测试套。[官方示例 List.test.ets](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/ets/test/List.test.ets#L16-L55)
4. Hypium 的 suite 循环对 spec 逐条 `await`：`beforeEach -> spec.asyncRun -> afterEach`，然后才进入下一 spec。[arkXtest `service.js`](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/service.js)（`asyncRunSpecs`，约 L677-L713）
5. 根 suite 全部完成后触发 `taskDone`；报告器在 `taskDone` 中调用 `finishTest()`。[arkXtest `service.js`](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/service.js)（`execute`，约 L513-L543）与 [arkXtest `OhReport.js`](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/module/report/OhReport.js)（`taskDone`，约 L42-L82）。

因此，一个测试文件/类中有很多 `it` 并不会为每条 case 新建 Runner 或 TestAbility。它们共享同一次测试任务的进程内状态，除非测试代码主动清理或重建。

## 2. TestAbility 与 EntryAbility 是否应分进程

### 已证实

- Stage 模型默认情况下，同一 bundle 名称的所有 UIAbility 都运行在同一主进程。[官方进程模型](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-models/process-model-stage.md#L14-L32)
- 官方 UITest 示例的 main 模块 EntryAbility 与 ohosTest 模块 TestAbility 都未配置 `process`。[main/module.json5](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/main/module.json5#L1-L35)、[ohosTest/module.json5](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/module.json5#L16-L50)
- UIAbility 的静态 `process` 字段从 API 14 起只在 PC/2in1、Tablet 生效；手机上不能把它当成通用隔离开关。[官方 module.json5 说明](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/quick-start/module-configuration-file.md#L315-L326)
- UITest 自身已经是客户端/服务端结构：客户端加载在测试应用进程，服务端是独立进程。[官方 UITest 架构](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-test/uitest-guidelines.md#L26-L40)
- 官方 FAQ 明确指出，不支持多个进程同时执行 UI 测试用例，否则可能出现 `uitest-api does not allow calling concurrently`。[官方 UITest FAQ](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-test/uitest-guidelines.md#L910-L926)

### 判断

**不建议把“TestAbility 单独进程”作为当前问题的首选修复。** 它没有官方示例背书、设备支持不通用，还可能把问题变成 UITest 多进程/IPC 兼容性问题。先证明 TestAbility 确实被销毁或进程确实退出，再决定是否需要架构隔离。

同进程的真实边界是：

- `UIAbilityContext.terminateSelf()` 的官方语义是销毁“UIAbility 自身”，并非 force-stop 应用。[官方 `terminateSelf`](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/reference/apis-ability-kit/js-apis-inner-application-uiAbilityContext.md#L617-L749)
- 进程内所有 Ability 都退出后，进程才进入销毁流程。[官方进程模型](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-models/process-model-stage.md#L31-L32)

官方资料没有承诺销毁 EntryAbility 会连带销毁 TestAbility，但当前 loopback 模拟器的正反对照已经证明：紧接 UI 操作直接销毁 EntryAbility，足以让测试任务被 AATool 判为 `App died`。除此之外仍要验证代码是否拿错了 Ability 实例，例如对当前 top ability 未校验名称便执行 `terminateSelf()`，从而实际销毁 TestAbility。

### 2026-08-11 loopback 模拟器正反对照

本项目增加了四条显式 case 的最小实验。第一条启动 EntryAbility 并完成 UI 操作，第二条销毁该 EntryAbility，第三、四条用于确认 Runner 是否继续：

- 不等待 safe point：第一条 Pass，第二条只有 start、没有 done，第三和第四条没有启动；`aa test` 返回 `TestFinished-ResultCode: -1` 和 `App died`。系统日志最后可见 `terminate EntryAbility`、`isLast:0`，随后 AATool 收到 `App died, code:-1`。
- 销毁前调用 `waitForAbilityRestartSafePoint()`（当前为 300ms）：4/4 Pass，耗时 3678ms。

因此，“快速销毁 EntryAbility”已在当前 loopback 模拟器成为一个可重复的整套停止路径；这不是对所有设备版本的通用平台结论。回归用例见 `AbilityRestartIsolation.test.ets`。真实项目仍应以 `App died`、最后一次 Ability 生命周期事件和 PID 日志确认是否命中同一原因。

### 2026-08-11 业务残留回调正反对照

这组实验没有在测试代码中调用 `terminateSelf()`、`finishTest()` 或并发 Driver API。测试的四条显式 case 只做以下动作：

1. 启动真实 EntryAbility，进入 `NetworkDemoPage`，确认业务故障注入任务已经由 `NetworkDemoViewModel` 创建，然后正常返回主页。
2. 等待上一页面的业务任务到期，并在主页执行普通控件查找。
3.、4. 继续执行普通主页控件查找，用于判断 Runner 是否还活着。

用同一个入口执行：

```bash
./uitest BusinessLifecycleStopReproUiTest
```

红态故意不在 `NetworkDemoViewModel.aboutToDisappear()` 清理业务任务。结果为：第 1 条 Pass（2693ms）；第 2 条只收到 start；第 3、4 条没有启动；随后报告 `TestFinished-ResultCode: -1`、`TestFinished-ResultMsg: App died`，命令退出码为 1。同期系统日志出现应用 `JS_ERROR` 和 `HandleAppDied appName=com.joker.kit`。

随后在业务 ViewModel 增加正常业务方法 `reset()`，由页面 `aboutToDisappear()` 主动调用。UITest 不调用该方法，也不在 case 钩子中替业务兜底清理。相同四条 case 为 4/4 Pass，最新一次 suite 耗时 6757ms，`OHOS_REPORT_CODE: 0`，命令退出码为 0。第 2 条 case 在页面退出后继续等待 4 秒，旧回调没有执行，后续两条 case 正常完成。故障注入默认关闭，正常 App 不会创建该诊断任务。

这个对照划清了责任边界：Timer、订阅、请求回调等资源本来就是业务生命周期的一部分，即使没有 UITest，业务也必须在退出或重置时释放。测试不能通过测试专属清理接口或 case 钩子替业务补漏；正常页面生命周期必须自行调用业务的 `reset()`/`dispose()`。UITest 在这里仅观察并验证清理结果。

这证明了一个**足以产生整组停止的业务侧机制**：页面退出后仍存活的回调若产生未处理异常，可以杀掉与 TestAbility 同进程的应用，后续 case 自然无法继续。它不能反向证明其他项目中所有 `Stopped` 都由定时器导致；实际项目仍要核对最后启动但未完成的 case、`App died/JS_ERROR` 与对应页面的 Timer、订阅、网络回调和协程清理。

## 3. 什么时候重启 Ability

官方公开 UITest 示例体现两种粒度：

- **测试套级启动一次并复用：** 多个 UI 操作 suite 在 `beforeAll` 启动目标 Ability，多个 `it` 复用同一页面实例。例如 [ScrollerEvent.test.ets](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/ets/test/operationExampleTest/ui/ScrollerEvent.test.ets#L24-L68)；第二条 case 会自行滚到底再回到顶部，不依赖第一条的结尾状态。
- **单条 case 自己启动并恢复：** 基础示例在 case 内启动 EntryAbility，完成验证后 `pressBack()`。[basicExample.test.ets](https://github.com/openharmony/applications_app_samples/blob/a826ab0e75fe51d028c1c5af58188e908736b53b/code/Project/Test/uitest/entry/src/ohosTest/ets/test/basicExampleTest/basicExample.test.ets#L34-L60)

官方示例中未找到“每条 case 先 `terminateSelf()` 再重启目标 Ability”的通用模式。基于框架生命周期和隔离成本，建议采用以下分层：

| 场景 | 建议重置方式 | 原因 |
| --- | --- | --- |
| 同一页面上的控件、滚动、输入测试 | suite 启动一次；每条 case 在开始时软重置到已知状态 | 快，且官方示例采用这种粒度 |
| 导航会离开基准页，但可可靠返回 | `beforeEach` 回到基准 route；case 内必要时 `pressBack`/点击返回 | 避免重建宿主生命周期 |
| 必须验证 `onCreate`、冷启动、状态恢复 | 只重启**明确识别的被测 Ability**，等待 destroy/create/foreground monitor 后再操作 | 冷启动本身是测试前提 |
| 必须验证进程死亡 | 单独测试任务，由任务外部编排重启 | 同进程 force-stop 会同时杀掉 TestAbility，无法保证连续 suite |
| TestAbility | 连续任务中绝不主动重启/销毁 | 它承载 Hypium；销毁会提前结束任务 |

“只重启明确识别的被测 Ability”意味着不能盲目终止 `getCurrentTopAbility()` 的返回值；至少先校验 `ability.context.abilityInfo.name`，更稳妥的是用 EntryAbility 专属 AbilityMonitor 保存实例并等待生命周期回调。

## 4. beforeEach / afterEach 的可靠状态隔离

### 框架提供什么、没有提供什么

官方文档只承诺：`beforeEach` 每条 case 前执行，`afterEach` 每条 case 后执行；没有声明自动清理页面、持久化存储、导航栈或业务单例。[官方基础流程说明](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-test/unittest-guidelines.md#L280-L347)

MockKit 也需要显式清理：`clear` 会还原被 mock 的实例；`clearAll` 清数据和内存，但不会还原被 mock 的函数。[官方 MockKit 说明](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-test/unittest-guidelines.md#L643-L664)

### 一个容易忽略的源码事实

当前 Hypium 的异步执行代码把 `beforeEach -> case -> afterEach` 放在同一个 `try` 中，而 `afterEach` 位于 case 之后。case 抛出断言、普通异常或 timeout rejection 时，控制流直接进入 `catch`，**不会执行该 case 的 `afterEach`**。[arkXtest `service.js`](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/service.js)（约 L693-L711）；ArkTS 静态实现也相同：[StaticSuite.ets](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src_static/module/service/StaticSuite.ets)（约 L241-L295）。

此外，timeout 包装器的 timer 只调用 `reject(...)`，没有中断或取消正在 `await func()` 的测试函数。因此 suite 收到 timeout Error 后可以继续下一条 spec，但上一条函数仍可能在后台执行。参见同一 [`service.js`](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/service.js) 的 `getFuncWithArgsZero/One/Two`（约 L78-L139）。

因此不能把下一条 case 的正确性只寄托在上一条 case 的 `afterEach`；也不能把 timeout 当成“case 已经停止执行”。

### 推荐基线

```text
beforeAll
  注册 TestAbility / EntryAbility 生命周期 monitor
  启动本 suite 的目标 Ability（如果 suite 共用一个页面）

beforeEach
  确认 TestAbility 仍存活
  确认当前是预期的被测 Ability/页面
  幂等恢复导航、弹窗、键盘、滚动和输入状态
  恢复或重建业务数据、Mock、监听器、计时器

it
  只执行该 case 的动作与断言
  必须执行的资源释放用 case 自身的 try/finally 保护

afterEach
  做 best-effort 清理、日志/截图采集、Mock 还原
  不作为下一 case 获得干净状态的唯一保证

afterAll
  移除 monitor/监听器；按需退出被测 Ability
  不销毁 TestAbility，由 Hypium 正常 taskDone -> finishTest
```

需要重置的状态至少应按项目实际情况逐项确认：导航栈和当前页面、滚动/输入/焦点、软键盘和弹窗、账户/权限态、Preferences/RDB/缓存、内存单例与全局事件、网络 Mock、延迟任务/计时器。这个清单是工程建议，不是 Hypium 自动保证项。

## 5. 会让后续 case 不再运行的已知路径

| 路径 | 一手证据 | 是否等同 DevEco `Stopped` |
| --- | --- | --- |
| TestAbility 被销毁 | arkXtest 模板的 `onDestroy()` 直接 `finishTest(..., -2)`：[TestAbility.ets](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src_static/testAbility/TestAbility.ets)（L22-L39） | 会提前结束测试；IDE 标签映射未公开 |
| 任意代码提前调用 `finishTest` | 官方 API 明确定义为“结束测试”：[AbilityDelegator.finishTest](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/reference/apis-test-kit/js-apis-inner-application-abilityDelegator.md#L1176-L1261) | 会结束；标签映射未公开 |
| `breakOnError=true` 且 case failure/error | 官方文档说明遇错即停，默认 false：[执行参数](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/application-test/unittest-guidelines.md#L137-L150)；源码中循环会 break，并打印明确的 breakOnError 消息 | 是框架有意停止剩余 case，但任务仍走正常 `taskDone/finishTest`；不应仅凭 `Stopped` 推断 |
| case timeout，`breakOnError=false` | timeout 包装器 reject 当前 Promise但不取消 case 函数：[service.js](https://gitcode.com/openharmony/arkXtest/blob/6d09b67d91158b4b1ebd4662e11b9f3bff45bc31/jsunit/src/service.js)（L78-L139）；suite 捕获并继续下一 spec（L685-L713） | **源码不支持“timeout 必然整套停止”**；但未结束的旧 case 可与新 case 并发，形成二次故障。外部工具另行杀任务的情况未在资料中证实 |
| 测试应用进程 force-stop、崩溃或所有 Ability 退出 | TestAbility 与 EntryAbility 默认同进程；进程内所有 Ability 退出后进程销毁 | 任务无法继续，但具体 UI 标签无公开映射 |
| UITest 异步 API 未 await / 多进程并发调用 | 官方 FAQ 给出明确错误 `uitest-api does not allow calling concurrently` | 本身是 case 错误；只有再叠加 breakOnError 或进程异常才会停止剩余 case |

## 6. 复现 `Stopped` 时必须采集的证据

官方 AbilityMonitor 支持 `onAbilityCreate`、`onAbilityForeground`、`onAbilityBackground`、`onAbilityDestroy`、WindowStage create/destroy 回调，适合建立完整时间线。[官方 AbilityMonitor](https://github.com/openharmony/docs/blob/f41b9345badd47c7ab0c263344cd7f4b5a549afb/zh-cn/application-dev/reference/apis-ability-kit/js-apis-inner-application-abilityMonitor.md#L22-L42)

建议压力复现用例每轮记录：

1. run id、suite、case、轮次、PID、时间戳。
2. TestAbility 与被测 Ability 的 create/foreground/background/destroy 回调。
3. 每次准备执行 `terminateSelf()` 前，记录目标 Ability 的 `abilityInfo.name`、moduleName 和实例标识；名称不匹配时禁止终止。
4. `OHOS_REPORT_STATUS_CODE: 1`（case start）和对应 case done 是否成对；最后一条完成的框架事件是什么。
5. 所有 `finishTest(msg, code)` 的消息与调用点，特别查找 `TestAbility onDestory unexpectedly!` 和 code `-2`。
6. 实际 aa test 参数，确认 `breakOnError`、`timeout`、`stress`。
7. 同一时间段的应用进程退出、native crash、JS exception、OOM/kill 日志。

只有出现下列证据之一，才可下相应结论：

- `TestAbility onAbilityDestroy` 紧接 `finishTest(..., -2)`：TestAbility 生命周期提前结束。
- 进程 PID 消失且有 crash/kill 记录：进程级终止。
- case Error 后出现 Hypium 的 `breakOnError model` 报告：配置导致遇错即停。
- 只有 `execute timeout ...ms`，随后仍出现下一 case start：只是 case timeout，不是整套停止。
- 只有 DevEco `Stopped`、没有上述链路：证据不足，不能归因。

## 7. 对当前方案的可执行建议

1. 先增加生命周期与 PID 观测，再通过加长流程/`stress` 连续运行复现，不先改进程模型。
2. 暂停“每条 case 盲目终止 top Ability”的做法；改为目标名称校验、销毁前 safe point 与 AbilityMonitor 等待。
3. 普通 UI case 采用“suite 启动一次 + beforeEach 幂等软重置”；冷启动/恢复类 case 单独分组，才重启被测 Ability。
4. 基线建立放在 `beforeEach`；`afterEach` 只做补充。必须执行的清理放入 case 自身 `try/finally`，规避 Hypium 异常路径跳过 `afterEach`。
5. 进程死亡测试单独运行，不与需要连续执行的普通 case 混在同一 Runner 生命周期内。

## 证据边界

- 没有找到 OpenHarmony/Hypium 官方材料把 DevEco UI 中的 `Stopped` 状态唯一映射到某个异常码或生命周期事件。
- 没有找到官方建议把 TestAbility 与 EntryAbility 分进程；相反，官方示例保持默认进程配置。
- 没有找到“`terminateSelf()` 正常调用会随机连带销毁同进程其他 UIAbility”的官方说明或源码证据。
- 官方公开 UITest 示例主要展示 API 使用，不等于完整的生产级隔离规范；本文的分层重置策略是在明确框架行为之上的工程建议，已与一手事实分开标注。
