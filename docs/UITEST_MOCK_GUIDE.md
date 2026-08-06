# HarmonyOS UITest Mock 示例

本项目使用 `@ohos/hypium 1.0.24` 的 `MockKit`，并用业务 `Provider` 把 Mock 仓库注入真实页面。
两者职责不同：

- `MockKit` 控制对象方法的返回值、动作、异常和调用次数。
- `Provider` 保证页面创建 ViewModel 时拿到测试对象，而不是真实网络仓库。
- `TestKit Driver` 只负责启动应用、操作控件和断言最终 UI，不负责 Mock。

## 可运行示例索引

MockKit API 示例位于
`feature/main/src/ohosTest/ets/test/specs/MockKit.spec.ets`：

| 场景 | 示例 |
| --- | --- |
| 精确参数返回 | `afterReturn` + `when(method)('goods-1')` |
| 任意参数 | `ArgumentMatchers.any` |
| 类型参数 | `anyString`、`anyNumber`、`anyBoolean`、`anyObj`、`anyFunction` |
| 正则参数 | `ArgumentMatchers.matchRegexs` |
| 动态行为 | `afterAction` |
| void 方法 | `afterReturnNothing` |
| 同步异常 | `afterThrow` |
| 异步异常 | `afterReturn(Promise.reject(...))` |
| 调用验证 | `once`、`never`、`times`、`atLeast`、`atMost` |
| 对象整体 Mock | `mockObject`（仅对象自有函数） |
| 恢复单个方法 | `ignoreMock` |
| 恢复对象方法 | `clear` |
| 第一次失败、第二次成功 | 计数器 + `afterAction` |

真实页面状态示例位于 `Network.spec.ets` 和 `NetworkList.spec.ets`：

- 固定成功响应并断言标题、副标题。
- Deferred Promise 保持 pending，严格断言 Loading → Success。
- `Promise.reject` 模拟传输层失败，断言网络错误页。
- 第一次返回业务失败，点击重试后第二次成功。
- 分页接口返回空列表，断言空态。
- 分页接口返回 Mock 数据，断言列表内容。
- UI 断言后再验证仓库调用次数，防止真实接口碰巧返回同类状态造成假阳性。

## 推荐写法

```ts
const mocker: MockKit = new MockKit();
const repository: GoodsRepository = new GoodsRepository();
const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
when(getGoodsInfo)('1').afterReturn(Promise.resolve(response));
GoodsRepositoryProvider.set(repository);

try {
  await page.openDirectly();
  await page.expectMockData();
  mocker.verify('getGoodsInfo', ['1']).once();
} finally {
  GoodsRepositoryProvider.reset();
  mocker.clear(repository);
}
```

Mock 必须在打开页面之前注入，因为 ViewModel 构造时会从 Provider 读取 Repository。
每个用例必须在 `finally` 中同时重置 Provider、恢复被替换的方法，避免污染后续用例。

## MockKit 边界

`MockKit.mockFunc` 是替换“某个对象上的方法”，它不会自动拦截以下对象：

- ES Module 静态 import；
- HTTP 请求和 WebSocket；
- Preferences、关系型数据库等持久化；
- 系统时间、权限、定位、相机等系统能力；
- ArkUI 控件和 TestKit Driver/HDC。

这些依赖应先抽成接口或 Provider，再注入 Fake/Mock。例如：

| 依赖 | 建议替身 |
| --- | --- |
| HTTP/WebSocket | Repository 或 DataSource Fake |
| Preferences | 内存 Key-Value Store |
| 数据库 | 临时数据库或 Repository Fake |
| 当前时间 | `Clock` 接口 + `FakeClock` |
| 权限/定位/相机 | Gateway 接口 + Fake |

## 版本注意事项

- 类方法通常位于 prototype，优先使用 `mockFunc(instance, instance.method)`。
- `mockObject` 只扫描对象的自有函数。本项目示例通过具名函数属性演示；普通类的 prototype
  方法不能指望被 `mockObject` 自动发现。
- `afterThrow` 在 1.0.24 中直接抛出配置值；异步失败应返回 `Promise.reject(new Error(...))`。
- MockKit 没有连续返回队列；使用计数器和 `afterAction` 明确实现调用序列。
- `clear(object)` 会恢复被替换的方法。1.0.24 的 `clearAll()` 只清空 MockKit 内部状态，不能代替
  `clear(object)` 恢复业务对象，因此清理时不要只调用 `clearAll()`。
- Mock 不等于跨进程替换。测试 HAP 与真实 entry HAP 的安装/启动关系仍由本项目 runner 负责。

## 执行

执行单个示例：

```bash
./uitest 'MainHarUiTest#retriesMockedBusinessFailureAndShowsData'
```

执行完整 HAR UITest：

```bash
./uitest MainHarUiTest
```

当前示例集已在 `127.0.0.1:5555` 模拟器完成正常构建模式回归：
`Tests run: 25, Failure: 0, Error: 0, Pass: 25, Ignore: 0`。
