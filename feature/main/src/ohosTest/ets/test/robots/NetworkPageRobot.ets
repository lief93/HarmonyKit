import { Driver } from '@kit.TestKit';
import { clickText, requireText, requireTextAbsent } from '../framework/UiDriver';
import { launchMain, openNetworkDemoPage } from '../support/HarmonyKitTestApp';
import {
  LOADING_TEXT,
  MAIN_CARD,
  MOCK_GOODS_SUB_TITLE,
  MOCK_GOODS_TITLE,
  NETWORK_PAGE_TITLE,
  START_TIMEOUT
} from '../support/TestValues';

export class NetworkPageRobot {
  private driver: Driver;

  constructor(driver: Driver) {
    this.driver = driver;
  }

  async openFromMain(): Promise<void> {
    await launchMain(this.driver);
    await clickText(this.driver, MAIN_CARD);
    await this.expectTitle();
  }

  async openDirectly(): Promise<void> {
    await openNetworkDemoPage(this.driver);
  }

  async expectTitle(): Promise<void> {
    await requireText(this.driver, NETWORK_PAGE_TITLE);
  }

  async expectMockData(): Promise<void> {
    await requireText(this.driver, MOCK_GOODS_TITLE, START_TIMEOUT);
    await requireText(this.driver, MOCK_GOODS_SUB_TITLE);
  }

  async expectLoading(): Promise<void> {
    await requireText(this.driver, LOADING_TEXT);
  }

  async expectMockTitleAbsent(): Promise<void> {
    await requireTextAbsent(this.driver, MOCK_GOODS_TITLE);
  }

  async expectLoadingAbsent(): Promise<void> {
    await requireTextAbsent(this.driver, LOADING_TEXT);
  }

  async waitForStateChange(): Promise<void> {
    await this.driver.delayMs(300);
  }

  async returnToMain(): Promise<void> {
    await this.driver.pressBack();
    await requireText(this.driver, MAIN_CARD);
  }
}
