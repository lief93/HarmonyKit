import { Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, expect, it } from '@ohos/hypium';

const MAIN_CARD: string = 'Network Demo';
const DESTINATION_TITLE: string = 'Base Network 示例';

export default function abilityTest() {
  describe('MainHarUiTest', () => {
    it('openPageFromMainHar', 0, async () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const want: Want = {
        bundleName: 'com.joker.kit',
        moduleName: 'entry',
        abilityName: 'EntryAbility'
      };
      await delegator.startAbility(want);

      const driver: Driver = Driver.create();
      const card = await driver.waitForComponent(ON.text(MAIN_CARD), 5000);
      expect(card !== null && card !== undefined).assertTrue();
      if (card === null || card === undefined) {
        throw new Error(`${MAIN_CARD} was not found`);
      }

      await card.click();
      const destination = await driver.waitForComponent(ON.text(DESTINATION_TITLE), 3000);
      expect(destination !== null && destination !== undefined).assertTrue();

      await driver.pressBack();
      const returnedCard = await driver.waitForComponent(ON.text(MAIN_CARD), 3000);
      expect(returnedCard !== null && returnedCard !== undefined).assertTrue();
    })
  })
}
