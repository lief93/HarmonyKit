import { UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { DemoNavigator, getNavPathStack } from 'navigation';
import { clickText, requireText } from '../framework/UiDriver';
import { MAIN_CARD, NETWORK_LIST_PAGE_TITLE, NETWORK_PAGE_TITLE, START_TIMEOUT } from './TestValues';

const RESTART_SETTLE_DELAY: number = 300;
const ENTRY_MODULE_NAME: string = 'entry';
const ENTRY_ABILITY_NAME: string = 'EntryAbility';
const MAIN_WANT: Want = {
  bundleName: 'com.joker.kit',
  moduleName: ENTRY_MODULE_NAME,
  abilityName: ENTRY_ABILITY_NAME
};
let hostAbility: UIAbility | undefined;

export function getStringResource(name: string): string {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  return delegator.getAppContext().resourceManager.getStringByNameSync(name);
}

export async function launchHost(driver: Driver): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const previousAbility: UIAbility | undefined = hostAbility;
  const previousNavPathStack: NavPathStack | undefined = getNavPathStack();
  let createdAbility: UIAbility | undefined;
  let destroyedAbility: UIAbility | undefined;
  const monitor: abilityDelegatorRegistry.AbilityMonitor = {
    abilityName: ENTRY_ABILITY_NAME,
    moduleName: ENTRY_MODULE_NAME,
    onAbilityCreate: (ability: UIAbility): void => {
      createdAbility = ability;
    },
    onAbilityDestroy: (ability: UIAbility): void => {
      destroyedAbility = ability;
    }
  };
  await delegator.addAbilityMonitor(monitor);

  try {
    if (previousAbility !== undefined) {
      await driver.delayMs(RESTART_SETTLE_DELAY);
      await previousAbility.context.terminateSelf();
      for (let attempt: number = 0; destroyedAbility !== previousAbility && attempt < 80; attempt++) {
        await driver.delayMs(100);
      }
      if (destroyedAbility !== previousAbility) {
        throw new Error('previous EntryAbility was not destroyed');
      }
    }

    await delegator.startAbility(MAIN_WANT);
    for (let attempt: number = 0; createdAbility === undefined && attempt < 80; attempt++) {
      await driver.delayMs(100);
    }
    if (createdAbility === undefined) {
      throw new Error('new EntryAbility was not created');
    }
    if (previousAbility !== undefined && createdAbility === previousAbility) {
      throw new Error('EntryAbility was reused instead of restarted');
    }
    hostAbility = createdAbility;

    let navPathStack: NavPathStack | undefined = getNavPathStack();
    for (let attempt: number = 0;
      (navPathStack === undefined || navPathStack === previousNavPathStack) && attempt < 80;
      attempt++) {
      await driver.delayMs(100);
      navPathStack = getNavPathStack();
    }
    if (navPathStack === undefined || navPathStack === previousNavPathStack) {
      throw new Error('new navigation stack was not initialized');
    }
    navPathStack.clear(false);
  } finally {
    await delegator.removeAbilityMonitor(monitor);
  }
}

export async function launchMain(driver: Driver): Promise<void> {
  await launchHost(driver);
  await clickText(driver, '核心', START_TIMEOUT);
  await requireText(driver, MAIN_CARD, START_TIMEOUT);
}

export async function openNetworkDemoPage(driver: Driver): Promise<void> {
  await launchHost(driver);
  DemoNavigator.toNetworkDemo();
  await requireText(driver, NETWORK_PAGE_TITLE, START_TIMEOUT);
}

export async function openNetworkListDemoPage(driver: Driver): Promise<void> {
  await launchHost(driver);
  DemoNavigator.toNetworkListDemo();
  await requireText(driver, NETWORK_LIST_PAGE_TITLE, START_TIMEOUT);
}
