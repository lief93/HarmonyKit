import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { MainPage } from '../../../../main/ets/view/MainPage';
import { MountedComponent, mountComponent } from '../framework/ComponentMount';
import { clickText, requireText } from '../framework/UiDriver';
import { getStringResource } from '../support/HarmonyKitTestApp';
import { DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT } from '../support/TestValues';

@Builder
function buildMainPageDirectly(): void {
  MainPage();
}

async function mountMainPage(driver: Driver): Promise<MountedComponent> {
  await requireText(driver, DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT);
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const testAbility: UIAbility = await delegator.getCurrentTopAbility();
  return mountComponent(testAbility, wrapBuilder(buildMainPageDirectly));
}

export default function mainPageTest(): void {
  describe('MainPageDirectUiTest', () => {
    it('showsCorePageWhenMountedIntoTestWindow', 0, async () => {
      const driver: Driver = Driver.create();
      const mounted: MountedComponent = await mountMainPage(driver);

      try {
        await requireText(driver, '网络请求', START_TIMEOUT);
        await requireText(driver, '状态管理');
      } finally {
        mounted.unmount();
      }

      await requireText(driver, DIRECT_MOUNT_HOST_TEXT);
    });

    it('switchesTabsWhenMountedIntoTestWindow', 0, async () => {
      const driver: Driver = Driver.create();
      const mounted: MountedComponent = await mountMainPage(driver);

      try {
        await clickText(driver, '导航');
        await requireText(driver, '带参跳转');
        await clickText(driver, '关于');
        await requireText(driver, '一个优雅的 HarmonyOS 快速开发框架');
      } finally {
        mounted.unmount();
      }
    });

    it('showsTextResolvedFromResourceKeys', 0, async () => {
      const driver: Driver = Driver.create();
      const mounted: MountedComponent = await mountMainPage(driver);

      try {
        await requireText(driver, getStringResource('core'), START_TIMEOUT);
        await requireText(driver, getStringResource('main_core_network_demo_title'));
      } finally {
        mounted.unmount();
      }
    });
  });
}
