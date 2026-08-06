import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { expect, it } from '@ohos/hypium';
import { BaseNetWorkUiState } from 'base';
import { BaseNetWorkView } from 'ui';
import { MountedComponent, mountComponent } from '../framework/ComponentMount';
import { clickText, requireText, requireTextAbsent } from '../framework/UiDriver';
import { getNavPathStack } from 'navigation';
import { DIRECT_MOUNT_HOST_TEXT, LOADING_TEXT, START_TIMEOUT } from '../support/TestValues';

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

@Builder
function buildBusinessComponentDirectly(): void {
  DirectMountNetworkStateHost();
}

export function registerDirectMountSpecs(): void {
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

    await driver.delayMs(300);
    await requireTextAbsent(driver, 'Direct mounted business component');
    await requireText(driver, DIRECT_MOUNT_HOST_TEXT);
  });
}
