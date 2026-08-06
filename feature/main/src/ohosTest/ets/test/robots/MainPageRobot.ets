import { Driver } from '@kit.TestKit';
import { clickText, requireText } from '../framework/UiDriver';
import { launchMain } from '../support/HarmonyKitTestApp';
import { MAIN_CARD, START_TIMEOUT } from '../support/TestValues';

export class MainPageRobot {
  private driver: Driver;

  constructor(driver: Driver) {
    this.driver = driver;
  }

  async open(): Promise<void> {
    await launchMain(this.driver);
  }

  async expectShell(): Promise<void> {
    await this.expectText('核心');
    await this.expectText('导航');
    await this.expectText('扩展');
    await this.expectText('关于');
    await this.expectText('Network List Demo');
  }

  async openTab(name: string): Promise<void> {
    await clickText(this.driver, name);
  }

  async expectText(text: string): Promise<void> {
    await requireText(this.driver, text);
  }

  async expectMainCard(): Promise<void> {
    await requireText(this.driver, MAIN_CARD, START_TIMEOUT);
  }
}
