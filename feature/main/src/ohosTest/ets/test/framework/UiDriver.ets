import { Component, Driver, ON, On } from '@kit.TestKit';
import { expect } from '@ohos/hypium';

const DEFAULT_TIMEOUT: number = 3000;

export async function requireComponent(driver: Driver, on: On, description: string,
  timeout: number = DEFAULT_TIMEOUT): Promise<Component> {
  const component: Component = await driver.waitForComponent(on, timeout);
  const found: boolean = component !== null && component !== undefined;
  if (!found) {
    throw new Error(`${description} was not found`);
  }
  expect(found).assertTrue();
  return component;
}

export async function requireText(driver: Driver, text: string,
  timeout: number = DEFAULT_TIMEOUT): Promise<Component> {
  return requireComponent(driver, ON.text(text), `text '${text}'`, timeout);
}

export async function requireTextAbsent(driver: Driver, text: string, timeout: number = 500): Promise<void> {
  const component: Component = await driver.waitForComponent(ON.text(text), timeout);
  const absent: boolean = component === null || component === undefined;
  if (!absent) {
    throw new Error(`text '${text}' is still visible`);
  }
  expect(absent).assertTrue();
}

export async function clickText(driver: Driver, text: string,
  timeout: number = DEFAULT_TIMEOUT): Promise<void> {
  const component: Component = await requireText(driver, text, timeout);
  await component.click();
}

export async function findTextInScroll(driver: Driver, text: string): Promise<Component> {
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

export async function clickTextInScroll(driver: Driver, text: string): Promise<void> {
  const component: Component = await findTextInScroll(driver, text);
  await component.click();
}
