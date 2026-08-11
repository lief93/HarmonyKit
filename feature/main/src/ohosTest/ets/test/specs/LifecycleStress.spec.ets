import { Driver } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { DemoPagesRobot } from '../robots/DemoPagesRobot';
import { MainPageRobot } from '../robots/MainPageRobot';
import { NavigationPageRobot } from '../robots/NavigationPageRobot';

const RESTART_STRESS_CASE_COUNT: number = 4;
const NAVIGATION_STRESS_CASE_COUNT: number = 2;
const STORAGE_STRESS_CASE_COUNT: number = 2;
const RESTART_CYCLES_PER_CASE: number = 3;
const LONG_FLOW_CYCLES_PER_CASE: number = 2;

export function registerLifecycleStressSpecs(): void {
  describe('LifecycleStressUiTest', () => {
  for (let caseIndex: number = 1; caseIndex <= RESTART_STRESS_CASE_COUNT; caseIndex++) {
    it(`survivesHostRestartCycles${caseIndex}`, 0, async () => {
      const driver: Driver = Driver.create();
      const mainPage: MainPageRobot = new MainPageRobot(driver);
      const demoPages: DemoPagesRobot = new DemoPagesRobot(driver);

      for (let cycle: number = 1; cycle <= RESTART_CYCLES_PER_CASE; cycle++) {
        await mainPage.open();
        await mainPage.expectShell();
        await mainPage.openTab('关于');
        await mainPage.expectText('一个优雅的 HarmonyOS 快速开发框架');

        await demoPages.openStateManagementDirectly();
        await demoPages.resetAndIncrementCounter();
        await demoPages.decrementCounter();
        await demoPages.returnToMain();
      }
    });
  }

  for (let caseIndex: number = 1; caseIndex <= NAVIGATION_STRESS_CASE_COUNT; caseIndex++) {
    it(`survivesLongNavigationFlow${caseIndex}`, 0, async () => {
      const driver: Driver = Driver.create();
      const navigation: NavigationPageRobot = new NavigationPageRobot(driver);

      for (let cycle: number = 1; cycle <= LONG_FLOW_CYCLES_PER_CASE; cycle++) {
        await navigation.openParameterizedRoute();
        await navigation.expectParameters();
        await navigation.returnToNavigationPage();

        const title: string = `Stress title ${caseIndex}-${cycle}`;
        const description: string = `Stress description ${caseIndex}-${cycle}`;
        await navigation.openResultRoute();
        await navigation.returnResult(title, description);
        await navigation.expectResult(title, description);
      }
    });
  }

  for (let caseIndex: number = 1; caseIndex <= STORAGE_STRESS_CASE_COUNT; caseIndex++) {
    it(`survivesLongScrollAndStorageFlow${caseIndex}`, 0, async () => {
      const driver: Driver = Driver.create();
      const demoPages: DemoPagesRobot = new DemoPagesRobot(driver);

      for (let cycle: number = 1; cycle <= LONG_FLOW_CYCLES_PER_CASE; cycle++) {
        await demoPages.openSafeArea();
        await demoPages.expectSafeAreaContent();
        await demoPages.openScreenAdaptFromSafeArea();
        await demoPages.expectScreenAdaptContent();

        const account: string = `stress-account-${caseIndex}-${cycle}-${Date.now()}`;
        await demoPages.openLocalStorage();
        await demoPages.saveAndLoadAccount(account);
        await demoPages.expectText(account);
      }
    });
  }
  });
}
