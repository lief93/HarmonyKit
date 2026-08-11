import { Component, Driver, ON, On, Rect } from '@kit.TestKit';
import { expect } from '@ohos/hypium';

const DEFAULT_TIMEOUT: number = 3000;
const DEFAULT_ABSENCE_TIMEOUT: number = 500;
const DEFAULT_POLL_INTERVAL: number = 100;
const ABILITY_RESTART_SETTLE_DELAY: number = 300;
const FAST_SCROLL_SPEED: number = 4000;
const FAST_SCROLL_MAX_SWIPES: number = 12;
const FAST_SCROLL_START_RATIO: number = 0.8;
const FAST_SCROLL_END_RATIO: number = 0.2;

// The loopback emulator can kill the test process when an ability is terminated
// immediately after the previous UI interaction, even after waitForIdle succeeds.
export async function waitForAbilityRestartSafePoint(driver: Driver): Promise<void> {
  await driver.delayMs(ABILITY_RESTART_SETTLE_DELAY);
}

export async function waitForUiIdle(driver: Driver, idleTime: number = 100,
  timeout: number = DEFAULT_TIMEOUT): Promise<void> {
  const idle: boolean = await driver.waitForIdle(idleTime, timeout);
  if (!idle) {
    throw new Error(`UI did not stay idle for ${idleTime}ms within ${timeout}ms`);
  }
  expect(idle).assertTrue();
}

export async function waitForCondition(driver: Driver, condition: () => boolean,
  description: string, timeout: number = DEFAULT_TIMEOUT): Promise<void> {
  const deadline: number = Date.now() + timeout;
  while (!condition()) {
    const remaining: number = deadline - Date.now();
    if (remaining <= 0) {
      throw new Error(`${description} was not satisfied within ${timeout}ms`);
    }
    await driver.delayMs(Math.min(DEFAULT_POLL_INTERVAL, remaining));
  }
}

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

export async function requireTextAbsent(driver: Driver, text: string,
  timeout: number = DEFAULT_ABSENCE_TIMEOUT): Promise<void> {
  const deadline: number = Date.now() + timeout;
  while (true) {
    const component: Component = await driver.findComponent(ON.text(text));
    const absent: boolean = component === null || component === undefined;
    if (absent) {
      expect(absent).assertTrue();
      return;
    }

    const remaining: number = deadline - Date.now();
    if (remaining <= 0) {
      throw new Error(`text '${text}' is still visible after ${timeout}ms`);
    }
    await driver.delayMs(Math.min(DEFAULT_POLL_INTERVAL, remaining));
  }
}

export async function clickText(driver: Driver, text: string,
  timeout: number = DEFAULT_TIMEOUT): Promise<void> {
  const component: Component = await requireText(driver, text, timeout);
  await component.click();
}

export async function fastScrollFind(driver: Driver, scroll: Component, on: On,
  description: string, maxSwipes: number = FAST_SCROLL_MAX_SWIPES): Promise<Component> {
  const bounds: Rect = await scroll.getBounds();
  const centerX: number = Math.round((bounds.left + bounds.right) / 2);
  const height: number = bounds.bottom - bounds.top;
  const startY: number = Math.round(bounds.top + height * FAST_SCROLL_START_RATIO);
  const endY: number = Math.round(bounds.top + height * FAST_SCROLL_END_RATIO);

  for (let swipeCount: number = 0; swipeCount <= maxSwipes; swipeCount++) {
    const component: Component = await driver.findComponent(on);
    if (component !== null && component !== undefined) {
      return component;
    }

    if (swipeCount < maxSwipes) {
      await driver.swipe(centerX, startY, centerX, endY, FAST_SCROLL_SPEED);
      await waitForUiIdle(driver);
    }
  }

  throw new Error(`${description} was not found after ${maxSwipes} fast scrolls`);
}

export async function findTextInScroll(driver: Driver, text: string): Promise<Component> {
  const visible: Component = await driver.findComponent(ON.text(text));
  if (visible !== null && visible !== undefined) {
    return visible;
  }

  const scroll: Component = await requireComponent(driver, ON.type('Scroll'), 'scroll container');
  return fastScrollFind(driver, scroll, ON.text(text), `text '${text}'`);
}

export async function clickTextInScroll(driver: Driver, text: string): Promise<void> {
  const component: Component = await findTextInScroll(driver, text);
  await component.click();
}
