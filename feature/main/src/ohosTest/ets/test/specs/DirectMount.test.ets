import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Component, Driver, ON } from '@kit.TestKit';
import { describe, expect, it } from '@ohos/hypium';
import { BaseNetWorkUiState } from 'base';
import { BaseNetWorkView } from 'ui';
import { MountedComponent, mountComponent } from '../framework/ComponentMount';
import {
  clickText, fastScrollFind, requireComponent, requireText, requireTextAbsent
} from '../framework/UiDriver';
import { getNavPathStack } from 'navigation';
import { DIRECT_MOUNT_HOST_TEXT, LOADING_TEXT, START_TIMEOUT } from '../support/TestValues';

const SCROLL_ITEM_COUNT: number = 50;
const FIRST_SCROLL_ITEM: string = 'Scroll item 1';
const NARROW_SCROLL_ITEM_INDEX: number = 16;
const NARROW_SCROLL_ITEM: string = `Scroll item ${NARROW_SCROLL_ITEM_INDEX}`;
const LAST_SCROLL_ITEM: string = `Scroll item ${SCROLL_ITEM_COUNT}`;

function createScrollItems(): number[] {
  const items: number[] = [];
  for (let item: number = 1; item <= SCROLL_ITEM_COUNT; item++) {
    items.push(item);
  }
  return items;
}

@ComponentV2
struct DirectMountNetworkStateHost {
  @Local
  private uiState: BaseNetWorkUiState = BaseNetWorkUiState.LOADING;

  @Builder
  private successContent(): void {
    Text('Direct mounted success');
  }

  build() {
    Column({ space: 12 }) {
      Text('Direct mounted business component');

      Button('Show direct mounted success')
        .onClick((): void => {
          this.uiState = BaseNetWorkUiState.SUCCESS;
        });

      BaseNetWorkView({
        uiState: this.uiState,
        content: (): void => this.successContent()
      });
    }
    .width('100%')
    .height('100%');
  }
}

@ComponentV2
struct DirectMountLongListHost {
  private readonly items: number[] = createScrollItems();

  build() {
    Scroll() {
      Column() {
        ForEach(this.items, (item: number) => {
          Text(`Scroll item ${item}`)
            .width('100%')
            .height(item === NARROW_SCROLL_ITEM_INDEX ? 24 : 72)
            .textAlign(TextAlign.Center);
        }, (item: number) => `${item}`);
      }
      .width('100%');
    }
    .width('100%')
    .height('100%');
  }
}

@Builder
function buildBusinessComponentDirectly(): void {
  DirectMountNetworkStateHost();
}

@Builder
function buildLongListDirectly(): void {
  DirectMountLongListHost();
}

export default function directMountTest(): void {
  describe('DirectMountUiTest', () => {
  it('mountsBusinessComponentIntoTestWindowWithoutRoute', 0, async () => {
    const driver: Driver = Driver.create();
    await requireText(driver, DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT);
    expect(getNavPathStack() === undefined).assertTrue();

    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const testAbility: UIAbility = await delegator.getCurrentTopAbility();
    const mounted: MountedComponent = await mountComponent(testAbility, wrapBuilder(buildBusinessComponentDirectly));

    try {
      await requireText(driver, 'Direct mounted business component', START_TIMEOUT);
      await requireText(driver, LOADING_TEXT);
      await clickText(driver, 'Show direct mounted success');
      await requireText(driver, 'Direct mounted success');
      await requireTextAbsent(driver, LOADING_TEXT);
    } finally {
      mounted.unmount();
    }

    await requireTextAbsent(driver, 'Direct mounted business component');
    await requireText(driver, DIRECT_MOUNT_HOST_TEXT);
  });

  it('fastScrollFindLocatesSmallAndLastOffscreenItems', 0, async () => {
    const driver: Driver = Driver.create();
    await requireText(driver, DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT);

    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const testAbility: UIAbility = await delegator.getCurrentTopAbility();
    const mounted: MountedComponent = await mountComponent(testAbility, wrapBuilder(buildLongListDirectly));

    try {
      await requireText(driver, FIRST_SCROLL_ITEM, START_TIMEOUT);
      const lastItemBeforeScroll: Component = await driver.findComponent(ON.text(LAST_SCROLL_ITEM));
      expect(lastItemBeforeScroll === null || lastItemBeforeScroll === undefined).assertTrue();

      const scroll: Component = await requireComponent(driver, ON.type('Scroll'), 'long list scroll');
      await fastScrollFind(driver, scroll, ON.text(NARROW_SCROLL_ITEM), 'narrow middle item');
      await requireText(driver, NARROW_SCROLL_ITEM);

      await fastScrollFind(driver, scroll, ON.text(LAST_SCROLL_ITEM), 'last item');
      await requireText(driver, LAST_SCROLL_ITEM);
      await requireTextAbsent(driver, FIRST_SCROLL_ITEM);
    } finally {
      mounted.unmount();
    }

    await requireText(driver, DIRECT_MOUNT_HOST_TEXT);
  });
  });
}
