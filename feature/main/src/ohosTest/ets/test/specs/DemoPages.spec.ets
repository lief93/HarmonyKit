import { Driver } from '@kit.TestKit';
import { it } from '@ohos/hypium';
import { DemoPagesRobot } from '../robots/DemoPagesRobot';

export function registerDemoPagesSpecs(): void {
  it('opensStatePageDirectlyAndUpdatesCounter', 0, async () => {
    const driver: Driver = Driver.create();
    const page: DemoPagesRobot = new DemoPagesRobot(driver);
    await page.openStateManagementDirectly();

    await page.resetAndIncrementCounter();
    await page.decrementCounter();
    await page.returnToMain();
  });

  it('opensSafeAreaAndScreenAdaptPages', 0, async () => {
    const driver: Driver = Driver.create();
    const page: DemoPagesRobot = new DemoPagesRobot(driver);
    await page.openSafeArea();

    await page.expectSafeAreaContent();
    await page.openScreenAdaptFromSafeArea();
    await page.expectScreenAdaptContent();
  });

  it('savesAndLoadsLocalStorageValue', 0, async () => {
    const driver: Driver = Driver.create();
    const page: DemoPagesRobot = new DemoPagesRobot(driver);
    const testAccount: string = `harmony-uitest-${Date.now()}`;
    await page.openLocalStorage();

    await page.saveAndLoadAccount(testAccount);
    await page.expectText(testAccount);
  });
}
