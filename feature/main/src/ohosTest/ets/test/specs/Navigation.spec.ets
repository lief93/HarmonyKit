import { Driver } from '@kit.TestKit';
import { it } from '@ohos/hypium';
import { NavigationPageRobot } from '../robots/NavigationPageRobot';
import { TEST_RESULT_DESC, TEST_RESULT_TITLE } from '../support/TestValues';

export function registerNavigationSpecs(): void {
  it('passesTypedNavigationArguments', 0, async () => {
    const driver: Driver = Driver.create();
    const page: NavigationPageRobot = new NavigationPageRobot(driver);
    await page.openParameterizedRoute();

    await page.expectParameters();
    await page.returnToNavigationPage();
  });

  it('returnsTypedNavigationResult', 0, async () => {
    const driver: Driver = Driver.create();
    const page: NavigationPageRobot = new NavigationPageRobot(driver);
    await page.openResultRoute();

    await page.returnResult(TEST_RESULT_TITLE, TEST_RESULT_DESC);
    await page.expectResult(TEST_RESULT_TITLE, TEST_RESULT_DESC);
  });
}
