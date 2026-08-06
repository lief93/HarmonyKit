import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { expect, it } from '@ohos/hypium';
import { getNavPathStack } from 'navigation';
import { MainPageRobot } from '../robots/MainPageRobot';
import { getStringResource, launchHost } from '../support/HarmonyKitTestApp';

export function registerMainPageSpecs(): void {
  it('launchShowsMainPage', 0, async () => {
    const driver: Driver = Driver.create();
    const page: MainPageRobot = new MainPageRobot(driver);
    await page.open();

    await page.expectShell();
  });

  it('restartHostResetsPageState', 0, async () => {
    const driver: Driver = Driver.create();
    const page: MainPageRobot = new MainPageRobot(driver);
    await page.open();
    await page.openTab('关于');
    await page.expectText('一个优雅的 HarmonyOS 快速开发框架');
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const previousAbility: UIAbility = await delegator.getCurrentTopAbility();
    const previousNavPathStack: NavPathStack | undefined = getNavPathStack();

    await launchHost(driver);

    const restartedAbility: UIAbility = await delegator.getCurrentTopAbility();
    const restartedNavPathStack: NavPathStack | undefined = getNavPathStack();
    expect(restartedAbility === previousAbility).assertFalse();
    expect(restartedNavPathStack === previousNavPathStack).assertFalse();
    await page.expectMainCard();
  });

  it('findsLocalizedTextFromResourceKeys', 0, async () => {
    const driver: Driver = Driver.create();
    const page: MainPageRobot = new MainPageRobot(driver);
    await page.open();

    const coreText: string = getStringResource('core');
    const networkDemoText: string = getStringResource('main_core_network_demo_title');
    await page.expectText(coreText);
    await page.expectText(networkDemoText);
  });

  it('switchesAcrossMainTabs', 0, async () => {
    const driver: Driver = Driver.create();
    const page: MainPageRobot = new MainPageRobot(driver);
    await page.open();

    await page.openTab('导航');
    await page.expectText('带参跳转');
    await page.expectText('结果回传');

    await page.openTab('扩展');
    await page.expectText('安全区');
    await page.expectText('屏幕适配');

    await page.openTab('关于');
    await page.expectText('HarmonyKit');
    await page.expectText('一个优雅的 HarmonyOS 快速开发框架');
    await page.expectText('框架文档');

    await page.openTab('核心');
    await page.expectMainCard();
  });
}
