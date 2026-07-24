import { UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Component, Driver, ON, On } from '@kit.TestKit';
import { describe, expect, it, MockKit, when } from '@ohos/hypium';
import { GoodsRepository, GoodsRepositoryProvider } from 'data';
import { Goods, NetworkResponse } from 'model';
import { DemoNavigator, getNavPathStack } from 'navigation';

const MAIN_CARD: string = 'Network Demo';
const NETWORK_PAGE_TITLE: string = 'Base Network 示例';
const TEST_RESULT_TITLE: string = 'UITest 回传标题';
const TEST_RESULT_DESC: string = 'UITest 回传说明';
const MOCK_GOODS_TITLE: string = 'Mock 商品标题';
const MOCK_GOODS_SUB_TITLE: string = 'Mock 商品副标题';
const LOADING_TEXT: string = '加载中...';
const DEFAULT_TIMEOUT: number = 3000;
const START_TIMEOUT: number = 8000;
const RESTART_SETTLE_DELAY: number = 300;
const ENTRY_MODULE_NAME: string = 'entry';
const ENTRY_ABILITY_NAME: string = 'EntryAbility';
const MAIN_WANT: Want = {
  bundleName: 'com.joker.kit',
  moduleName: ENTRY_MODULE_NAME,
  abilityName: ENTRY_ABILITY_NAME
};
let hostAbility: UIAbility | undefined;

class Deferred<T> {
  readonly promise: Promise<T>;
  private complete: (value: T) => void = (_value: T): void => {
  };

  constructor() {
    this.promise = new Promise<T>((resolve) => {
      this.complete = (value: T): void => resolve(value);
    });
  }

  resolve(value: T): void {
    this.complete(value);
  }
}

function createDeferred<T>(): Deferred<T> {
  return new Deferred<T>();
}

function createMockGoodsResponse(): NetworkResponse<Goods> {
  const goods: Goods = new Goods();
  goods.id = 1;
  goods.title = MOCK_GOODS_TITLE;
  goods.subTitle = MOCK_GOODS_SUB_TITLE;
  const response: NetworkResponse<Goods> = new NetworkResponse<Goods>();
  response.data = goods;
  return response;
}

function getStringResource(name: string): string {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  return delegator.getAppContext().resourceManager.getStringByNameSync(name);
}

async function requireComponent(driver: Driver, on: On, description: string,
  timeout: number = DEFAULT_TIMEOUT): Promise<Component> {
  const component: Component = await driver.waitForComponent(on, timeout);
  const found: boolean = component !== null && component !== undefined;
  if (!found) {
    throw new Error(`${description} was not found`);
  }
  expect(found).assertTrue();
  return component;
}

async function requireText(driver: Driver, text: string, timeout: number = DEFAULT_TIMEOUT): Promise<Component> {
  return requireComponent(driver, ON.text(text), `text '${text}'`, timeout);
}

async function requireTextAbsent(driver: Driver, text: string, timeout: number = 500): Promise<void> {
  const component: Component = await driver.waitForComponent(ON.text(text), timeout);
  const absent: boolean = component === null || component === undefined;
  if (!absent) {
    throw new Error(`text '${text}' is still visible`);
  }
  expect(absent).assertTrue();
}

async function clickText(driver: Driver, text: string, timeout: number = DEFAULT_TIMEOUT): Promise<void> {
  const component: Component = await requireText(driver, text, timeout);
  await component.click();
}

async function findTextInScroll(driver: Driver, text: string): Promise<Component> {
  const visible: Component = await driver.waitForComponent(ON.text(text), 500);
  if (visible !== null && visible !== undefined) {
    return visible;
  }

  const scroll: Component = await requireComponent(driver, ON.type('Scroll'), 'scroll container');
  const result: Component = await scroll.scrollSearch(ON.text(text));
  const found: boolean = result !== null && result !== undefined;
  if (!found) {
    throw new Error(`text '${text}' was not found in scroll container`);
  }
  expect(found).assertTrue();
  return result;
}

async function clickTextInScroll(driver: Driver, text: string): Promise<void> {
  const component: Component = await findTextInScroll(driver, text);
  await component.click();
}

async function launchHost(driver: Driver): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const previousAbility: UIAbility | undefined = hostAbility;
  const previousNavPathStack: NavPathStack | undefined = getNavPathStack();
  let createdAbility: UIAbility | undefined;
  let destroyedAbility: UIAbility | undefined;
  const monitor: abilityDelegatorRegistry.AbilityMonitor = {
    abilityName: ENTRY_ABILITY_NAME,
    moduleName: ENTRY_MODULE_NAME,
    onAbilityCreate: (ability: UIAbility): void => {
      createdAbility = ability;
    },
    onAbilityDestroy: (ability: UIAbility): void => {
      destroyedAbility = ability;
    }
  };
  await delegator.addAbilityMonitor(monitor);

  try {
    if (previousAbility !== undefined) {
      await driver.delayMs(RESTART_SETTLE_DELAY);
      await previousAbility.context.terminateSelf();
      for (let attempt: number = 0; destroyedAbility !== previousAbility && attempt < 80; attempt++) {
        await driver.delayMs(100);
      }
      if (destroyedAbility !== previousAbility) {
        throw new Error('previous EntryAbility was not destroyed');
      }
    }

    await delegator.startAbility(MAIN_WANT);
    for (let attempt: number = 0; createdAbility === undefined && attempt < 80; attempt++) {
      await driver.delayMs(100);
    }
    if (createdAbility === undefined) {
      throw new Error('new EntryAbility was not created');
    }
    if (previousAbility !== undefined && createdAbility === previousAbility) {
      throw new Error('EntryAbility was reused instead of restarted');
    }
    hostAbility = createdAbility;

    let navPathStack: NavPathStack | undefined = getNavPathStack();
    for (let attempt: number = 0;
      (navPathStack === undefined || navPathStack === previousNavPathStack) && attempt < 80;
      attempt++) {
      await driver.delayMs(100);
      navPathStack = getNavPathStack();
    }
    if (navPathStack === undefined || navPathStack === previousNavPathStack) {
      throw new Error('new navigation stack was not initialized');
    }
    navPathStack.clear(false);
  } finally {
    await delegator.removeAbilityMonitor(monitor);
  }
}

async function launchMain(driver: Driver): Promise<void> {
  await launchHost(driver);

  await clickText(driver, '核心', START_TIMEOUT);
  await requireText(driver, MAIN_CARD, START_TIMEOUT);
}

async function openNetworkDemoPage(driver: Driver): Promise<void> {
  await launchHost(driver);
  DemoNavigator.toNetworkDemo();
  await requireText(driver, NETWORK_PAGE_TITLE, START_TIMEOUT);
}

export default function abilityTest() {
  describe('MainHarUiTest', () => {
    it('launchShowsMainPage', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await requireText(driver, '核心');
      await requireText(driver, '导航');
      await requireText(driver, '扩展');
      await requireText(driver, '关于');
      await requireText(driver, 'Network List Demo');
    });

    it('restartHostResetsPageState', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);
      await clickText(driver, '关于');
      await requireText(driver, '一个优雅的 HarmonyOS 快速开发框架');
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const previousAbility: UIAbility = await delegator.getCurrentTopAbility();
      const previousNavPathStack: NavPathStack | undefined = getNavPathStack();

      await launchHost(driver);

      const restartedAbility: UIAbility = await delegator.getCurrentTopAbility();
      const restartedNavPathStack: NavPathStack | undefined = getNavPathStack();
      expect(restartedAbility === previousAbility).assertFalse();
      expect(restartedNavPathStack === previousNavPathStack).assertFalse();
      await requireText(driver, MAIN_CARD, START_TIMEOUT);
    });

    it('findsLocalizedTextFromResourceKeys', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      const coreText: string = getStringResource('core');
      const networkDemoText: string = getStringResource('main_core_network_demo_title');
      await requireText(driver, coreText);
      await requireText(driver, networkDemoText);
    });

    it('switchesAcrossMainTabs', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await clickText(driver, '导航');
      await requireText(driver, '带参跳转');
      await requireText(driver, '结果回传');

      await clickText(driver, '扩展');
      await requireText(driver, '安全区');
      await requireText(driver, '屏幕适配');

      await clickText(driver, '关于');
      await requireText(driver, 'HarmonyKit');
      await requireText(driver, '一个优雅的 HarmonyOS 快速开发框架');
      await requireText(driver, '框架文档');

      await clickText(driver, '核心');
      await requireText(driver, MAIN_CARD);
    });

    it('opensNetworkPageAndReturns', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await clickText(driver, MAIN_CARD);
      await requireText(driver, NETWORK_PAGE_TITLE);

      await driver.pressBack();
      await requireText(driver, MAIN_CARD);
    });

    it('showsMockedNetworkData', 0, async () => {
      const mocker: MockKit = new MockKit();
      const repository: GoodsRepository = new GoodsRepository();
      const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
      const response: NetworkResponse<Goods> = createMockGoodsResponse();
      when(getGoodsInfo)('1').afterReturn(Promise.resolve(response));
      GoodsRepositoryProvider.set(repository);

      try {
        const driver: Driver = Driver.create();
        await launchMain(driver);
        await clickText(driver, MAIN_CARD);

        await requireText(driver, NETWORK_PAGE_TITLE);
        await requireText(driver, MOCK_GOODS_TITLE, START_TIMEOUT);
        await requireText(driver, MOCK_GOODS_SUB_TITLE);
      } finally {
        GoodsRepositoryProvider.reset();
        mocker.clear(repository);
      }
    });

    it('showsLoadingUntilMockedNetworkCompletes', 0, async () => {
      const mocker: MockKit = new MockKit();
      const repository: GoodsRepository = new GoodsRepository();
      const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
      const pendingRequest: Deferred<NetworkResponse<Goods>> = createDeferred<NetworkResponse<Goods>>();
      const response: NetworkResponse<Goods> = createMockGoodsResponse();
      when(getGoodsInfo)('1').afterReturn(pendingRequest.promise);
      GoodsRepositoryProvider.set(repository);

      try {
        const driver: Driver = Driver.create();
        await openNetworkDemoPage(driver);

        await requireText(driver, LOADING_TEXT);
        await requireTextAbsent(driver, MOCK_GOODS_TITLE);

        pendingRequest.resolve(response);

        await requireText(driver, MOCK_GOODS_TITLE, START_TIMEOUT);
        await requireText(driver, MOCK_GOODS_SUB_TITLE);
        await driver.delayMs(300);
        await requireTextAbsent(driver, LOADING_TEXT);
      } finally {
        pendingRequest.resolve(response);
        GoodsRepositoryProvider.reset();
        mocker.clear(repository);
      }
    });

    it('passesTypedNavigationArguments', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await clickText(driver, '导航');
      await clickText(driver, '带参跳转');
      await requireText(driver, '10001');
      await requireText(driver, '示例商品');

      await driver.pressBack();
      await requireText(driver, '导航拦截');
    });

    it('returnsTypedNavigationResult', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await clickText(driver, '导航');
      await clickText(driver, '结果回传');

      const titleInput: Component = await requireComponent(
        driver,
        ON.type('TextInput').hint('请输入标题'),
        'result title input'
      );
      const descInput: Component = await requireComponent(
        driver,
        ON.type('TextInput').hint('请输入说明'),
        'result description input'
      );
      await titleInput.inputText(TEST_RESULT_TITLE);
      await descInput.inputText(TEST_RESULT_DESC);
      await clickTextInScroll(driver, '带参返回');

      await requireText(driver, '回传标题');
      await requireText(driver, TEST_RESULT_TITLE);
      await requireText(driver, '回传说明');
      await requireText(driver, TEST_RESULT_DESC);
    });

    it('opensStatePageDirectlyAndUpdatesCounter', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      DemoNavigator.toStateManagement();
      await requireText(driver, '状态管理示例');

      await clickTextInScroll(driver, '重置');
      await clickTextInScroll(driver, '＋');
      await requireText(driver, '1');
      await clickTextInScroll(driver, '－');
      await requireText(driver, '0');

      await driver.pressBack();
      await requireText(driver, MAIN_CARD);
    });

    it('opensSafeAreaAndScreenAdaptPages', 0, async () => {
      const driver: Driver = Driver.create();
      await launchMain(driver);

      await clickText(driver, '扩展');
      await clickText(driver, '安全区');
      await requireText(driver, '安全区示例');
      await requireText(driver, '以下数值单位为 vp');
      await requireText(driver, '顶部安全区');
      await requireText(driver, '底部安全区');

      await driver.pressBack();
      await clickText(driver, '屏幕适配');
      await requireText(driver, '屏幕适配示例');
      await requireText(driver, '断点类型');
      await requireText(driver, '网格项 1');
    });

    it('savesAndLoadsLocalStorageValue', 0, async () => {
      const driver: Driver = Driver.create();
      const testAccount: string = `harmony-uitest-${Date.now()}`;
      await launchMain(driver);

      await clickTextInScroll(driver, '本地存储');
      await requireText(driver, '本地存储示例');

      const accountInput: Component = await requireComponent(
        driver,
        ON.type('TextInput').hint('请输入账号'),
        'account input'
      );
      await accountInput.clearText();
      await accountInput.inputText(testAccount);
      await clickTextInScroll(driver, '保存');
      await driver.delayMs(300);

      await accountInput.clearText();
      await clickTextInScroll(driver, '读取');
      await requireText(driver, testAccount);
    });
  });
}
