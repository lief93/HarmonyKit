import { Driver } from '@kit.TestKit';
import { requireText } from '../framework/UiDriver';
import { openNetworkListDemoPage } from '../support/HarmonyKitTestApp';
import {
  EMPTY_DATA_TEXT,
  MOCK_GOODS_SUB_TITLE,
  MOCK_GOODS_TITLE,
  NETWORK_LIST_PAGE_TITLE,
  START_TIMEOUT
} from '../support/TestValues';

export class NetworkListPageRobot {
  private driver: Driver;

  constructor(driver: Driver) {
    this.driver = driver;
  }

  async openDirectly(): Promise<void> {
    await openNetworkListDemoPage(this.driver);
  }

  async expectTitle(): Promise<void> {
    await requireText(this.driver, NETWORK_LIST_PAGE_TITLE);
  }

  async expectEmpty(): Promise<void> {
    await requireText(this.driver, EMPTY_DATA_TEXT, START_TIMEOUT);
  }

  async expectMockData(): Promise<void> {
    await requireText(this.driver, MOCK_GOODS_TITLE, START_TIMEOUT);
    await requireText(this.driver, MOCK_GOODS_SUB_TITLE);
  }
}
