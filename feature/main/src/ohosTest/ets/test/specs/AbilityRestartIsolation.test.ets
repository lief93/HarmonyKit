import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver } from '@kit.TestKit';
import { describe, expect, it } from '@ohos/hypium';
import { requireText, waitForAbilityRestartSafePoint } from '../framework/UiDriver';
import { launchHost } from '../support/HarmonyKitTestApp';
import { DIRECT_MOUNT_HOST_TEXT } from '../support/TestValues';

let entryAbility: UIAbility | undefined;

async function delayWithoutDriver(milliseconds: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => resolve(), milliseconds);
  });
}

export default function abilityRestartIsolationTest(): void {
  describe('AbilityRestartIsolationUiTest', () => {
    it('opensEntryAbilityBeforeRestart', 0, async () => {
      const driver: Driver = Driver.create();
      await launchHost(driver);
      entryAbility = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      expect(entryAbility.context.abilityInfo.name).assertEqual('EntryAbility');
    });

    it('waitsForSafePointBeforeTerminatingEntryAbility', 0, async () => {
      if (entryAbility === undefined) {
        throw new Error('EntryAbility from the previous case is missing');
      }

      await waitForAbilityRestartSafePoint(Driver.create());
      await entryAbility.context.terminateSelf();
      await delayWithoutDriver(500);
    });

    it('continuesAfterEntryAbilityTermination', 0, () => {
      expect(true).assertTrue();
    });

    it('keepsTestAbilityDriverAvailable', 0, async () => {
      await requireText(Driver.create(), DIRECT_MOUNT_HOST_TEXT);
    });
  });
}
