import { Component, Driver, ON } from '@kit.TestKit';
import { clickText, clickTextInScroll, requireComponent, requireText } from '../framework/UiDriver';
import { launchMain } from '../support/HarmonyKitTestApp';

export class NavigationPageRobot {
  private driver: Driver;

  constructor(driver: Driver) {
    this.driver = driver;
  }

  async openParameterizedRoute(): Promise<void> {
    await launchMain(this.driver);
    await clickText(this.driver, '导航');
    await clickText(this.driver, '带参跳转');
  }

  async expectParameters(): Promise<void> {
    await requireText(this.driver, '10001');
    await requireText(this.driver, '示例商品');
  }

  async returnToNavigationPage(): Promise<void> {
    await this.driver.pressBack();
    await requireText(this.driver, '导航拦截');
  }

  async openResultRoute(): Promise<void> {
    await launchMain(this.driver);
    await clickText(this.driver, '导航');
    await clickText(this.driver, '结果回传');
  }

  async returnResult(title: string, description: string): Promise<void> {
    const titleInput: Component = await requireComponent(
      this.driver,
      ON.type('TextInput').hint('请输入标题'),
      'result title input'
    );
    const descInput: Component = await requireComponent(
      this.driver,
      ON.type('TextInput').hint('请输入说明'),
      'result description input'
    );
    await titleInput.inputText(title);
    await descInput.inputText(description);
    await clickTextInScroll(this.driver, '带参返回');
  }

  async expectResult(title: string, description: string): Promise<void> {
    await requireText(this.driver, '回传标题');
    await requireText(this.driver, title);
    await requireText(this.driver, '回传说明');
    await requireText(this.driver, description);
  }
}
