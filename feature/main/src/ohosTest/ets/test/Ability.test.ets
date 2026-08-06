import { describe } from '@ohos/hypium';
import { registerDemoPagesSpecs } from './specs/DemoPages.spec';
import { registerMainPageSpecs } from './specs/MainPage.spec';
import { registerNavigationSpecs } from './specs/Navigation.spec';
import { registerNetworkSpecs } from './specs/Network.spec';

export default function abilityTest() {
  describe('MainHarUiTest', () => {
    registerMainPageSpecs();
    registerNetworkSpecs();
    registerNavigationSpecs();
    registerDemoPagesSpecs();
  });
}
