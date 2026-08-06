import { describe } from '@ohos/hypium';
import { registerDirectMountSpecs } from './specs/DirectMount.spec';
import { registerDemoPagesSpecs } from './specs/DemoPages.spec';
import { registerMainPageSpecs } from './specs/MainPage.spec';
import { registerMockKitSpecs } from './specs/MockKit.spec';
import { registerNavigationSpecs } from './specs/Navigation.spec';
import { registerNetworkSpecs } from './specs/Network.spec';
import { registerNetworkListSpecs } from './specs/NetworkList.spec';

export default function abilityTest() {
  describe('MainHarUiTest', () => {
    registerDirectMountSpecs();
    registerMainPageSpecs();
    registerMockKitSpecs();
    registerNetworkSpecs();
    registerNetworkListSpecs();
    registerNavigationSpecs();
    registerDemoPagesSpecs();
  });
}
