import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { MainPage } from '../../../../main/ets/view/MainPage';
import { MountedComponent, mountComponent } from '../framework/ComponentMount';
import { clickText, findTextInScroll, requireText, waitForUiIdle } from '../framework/UiDriver';
import { DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT } from '../support/TestValues';

@Builder
function buildMainPageForStress(): void {
  MainPage();
}

async function mountMainPage(driver: Driver): Promise<MountedComponent> {
  await requireText(driver, DIRECT_MOUNT_HOST_TEXT, START_TIMEOUT);
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const testAbility: UIAbility = await delegator.getCurrentTopAbility();
  return mountComponent(testAbility, wrapBuilder(buildMainPageForStress));
}

async function exerciseAllMainTabs(driver: Driver): Promise<void> {
  await requireText(driver, 'Network Demo', START_TIMEOUT);

  await clickText(driver, '导航');
  await requireText(driver, '带参跳转');

  await clickText(driver, '扩展');
  await requireText(driver, '安全区');
  await requireText(driver, '屏幕适配');

  await clickText(driver, '关于');
  await requireText(driver, '一个优雅的 HarmonyOS 快速开发框架');
  await findTextInScroll(driver, 'IBest-ORM');

  await clickText(driver, '核心');
  await requireText(driver, 'Network Demo');
  await waitForUiIdle(driver);
}

async function runMountCycle(driver: Driver): Promise<void> {
  const mounted: MountedComponent = await mountMainPage(driver);
  try {
    await exerciseAllMainTabs(driver);
  } finally {
    mounted.unmount();
  }

  await requireText(driver, DIRECT_MOUNT_HOST_TEXT);
}

export default function mainPageStressTest(): void {
  describe('MainPageStressUiTest', () => {
    it('survivesRepeatedMountAndTabCycles1', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles2', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles3', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles4', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles5', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles6', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles7', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles8', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles9', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles10', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles11', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });

    it('survivesRepeatedMountAndTabCycles12', 0, async () => {
      const driver: Driver = Driver.create();
      await runMountCycle(driver);
      await runMountCycle(driver);
      await runMountCycle(driver);
    });
  });
}
