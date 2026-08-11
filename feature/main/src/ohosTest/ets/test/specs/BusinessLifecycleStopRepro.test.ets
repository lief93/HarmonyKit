import { Driver } from '@kit.TestKit';
import { afterAll, beforeAll, describe, expect, it } from '@ohos/hypium';
import { LifecycleFaultInjection } from 'base';
import { requireText } from '../framework/UiDriver';
import { openNetworkDemoPage } from '../support/HarmonyKitTestApp';
import { MAIN_CARD } from '../support/TestValues';

function delayWithoutDriver(milliseconds: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => resolve(), milliseconds);
  });
}

export default function businessLifecycleStopReproTest(): void {
  describe('BusinessLifecycleStopReproUiTest', () => {
    beforeAll(() => {
      LifecycleFaultInjection.enableStaleCallbackCrash();
    });

    afterAll(() => {
      LifecycleFaultInjection.disableStaleCallbackCrash();
    });

    it('opensAndLeavesBusinessPageNormally', 0, async () => {
      const driver: Driver = Driver.create();
      await openNetworkDemoPage(driver);
      expect(LifecycleFaultInjection.wasStaleCallbackScheduled()).assertTrue();
      await driver.pressBack();
      await requireText(driver, MAIN_CARD);
    });

    it('continuesNormalUiWorkWhileOldBusinessCallbackBecomesDue', 0, async () => {
      await delayWithoutDriver(4000);
      await requireText(Driver.create(), MAIN_CARD);
      expect(LifecycleFaultInjection.wasStaleCallbackCleared()).assertTrue();
    });

    it('reachesFollowerCaseAfterBusinessCallback', 0, async () => {
      await requireText(Driver.create(), MAIN_CARD);
    });

    it('keepsDriverUsableAfterBusinessCallback', 0, async () => {
      await requireText(Driver.create(), MAIN_CARD);
    });
  });
}
