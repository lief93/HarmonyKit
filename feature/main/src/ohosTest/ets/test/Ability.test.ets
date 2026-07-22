import { Want } from '@kit.AbilityKit';
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
const DEFAULT_TIMEOUT: number = 3000;
const START_TIMEOUT: number = 8000;
const MAIN_WANT: Want = {
  bundleName: 'com.joker.kit',
  moduleName: 'entry',
  abilityName: 'EntryAbility'
};

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

async function launchMain(driver: Driver): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  await delegator.startAbility(MAIN_WANT);

  let navPathStack: NavPathStack | undefined = getNavPathStack();
  for (let attempt: number = 0; navPathStack === undefined && attempt < 10; attempt++) {
    await driver.delayMs(100);
    navPathStack = getNavPathStack();
  }
  if (navPathStack === undefined) {
    throw new Error('navigation stack was not initialized');
  }
  navPathStack.clear(false);

  await clickText(driver, '核心', START_TIMEOUT);
  await requireText(driver, MAIN_CARD, START_TIMEOUT);
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
      const goods: Goods = new Goods();
      goods.id = 1;
      goods.title = MOCK_GOODS_TITLE;
      goods.subTitle = MOCK_GOODS_SUB_TITLE;
      const response: NetworkResponse<Goods> = new NetworkResponse<Goods>();
      response.data = goods;
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
