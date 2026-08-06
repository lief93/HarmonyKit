import { Component, Driver, ON } from '@kit.TestKit';
import { DemoNavigator } from 'navigation';
import { clickText, clickTextInScroll, requireComponent, requireText } from '../framework/UiDriver';
import { launchMain } from '../support/HarmonyKitTestApp';
import { MAIN_CARD } from '../support/TestValues';

export class DemoPagesRobot {
  private driver: Driver;

  constructor(driver: Driver) {
    this.driver = driver;
  }

  async openStateManagementDirectly(): Promise<void> {
    await launchMain(this.driver);
    DemoNavigator.toStateManagement();
    await requireText(this.driver, '状态管理示例');
  }

  async resetAndIncrementCounter(): Promise<void> {
    await clickTextInScroll(this.driver, '重置');
    await clickTextInScroll(this.driver, '＋');
    await requireText(this.driver, '1');
  }

  async decrementCounter(): Promise<void> {
    await clickTextInScroll(this.driver, '－');
    await requireText(this.driver, '0');
  }

  async returnToMain(): Promise<void> {
    await this.driver.pressBack();
    await requireText(this.driver, MAIN_CARD);
  }

  async openSafeArea(): Promise<void> {
    await launchMain(this.driver);
    await clickText(this.driver, '扩展');
    await clickText(this.driver, '安全区');
  }

  async expectSafeAreaContent(): Promise<void> {
    await requireText(this.driver, '安全区示例');
    await requireText(this.driver, '以下数值单位为 vp');
    await requireText(this.driver, '顶部安全区');
    await requireText(this.driver, '底部安全区');
  }

  async openScreenAdaptFromSafeArea(): Promise<void> {
    await this.driver.pressBack();
    await clickText(this.driver, '屏幕适配');
  }

  async expectScreenAdaptContent(): Promise<void> {
    await requireText(this.driver, '屏幕适配示例');
    await requireText(this.driver, '断点类型');
    await requireText(this.driver, '网格项 1');
  }

  async openLocalStorage(): Promise<void> {
    await launchMain(this.driver);
    await clickTextInScroll(this.driver, '本地存储');
    await requireText(this.driver, '本地存储示例');
  }

  async saveAndLoadAccount(account: string): Promise<void> {
    const accountInput: Component = await requireComponent(
      this.driver,
      ON.type('TextInput').hint('请输入账号'),
      'account input'
    );
    await accountInput.clearText();
    await accountInput.inputText(account);
    await clickTextInScroll(this.driver, '保存');
    await this.driver.delayMs(300);

    await accountInput.clearText();
    await clickTextInScroll(this.driver, '读取');
  }

  async expectText(text: string): Promise<void> {
    await requireText(this.driver, text);
  }
}
