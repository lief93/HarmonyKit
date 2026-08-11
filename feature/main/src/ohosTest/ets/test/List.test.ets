import { abilityDelegatorRegistry } from '@kit.TestKit';
import abilityRestartIsolationTest from './specs/AbilityRestartIsolation.test';
import businessLifecycleStopReproTest from './specs/BusinessLifecycleStopRepro.test';
import directMountTest from './specs/DirectMount.test';
import { registerDemoPagesSpecs } from './specs/DemoPages.spec';
import { registerLifecycleStressSpecs } from './specs/LifecycleStress.spec';
import mainPageTest from './specs/MainPage.test';
import mainPageStressTest from './specs/MainPageStress.test';
import { registerMainPageSpecs } from './specs/MainPageFlow.spec';
import mockKitTest from './specs/MockKit.test';
import { registerNavigationSpecs } from './specs/Navigation.spec';
import { registerNetworkSpecs } from './specs/Network.spec';
import { registerNetworkListSpecs } from './specs/NetworkList.spec';
import stateLeakDiagnosticTest from './specs/StateLeakDiagnostic.test';

const ABILITY_RESTART_ISOLATION_CLASS: string = 'AbilityRestartIsolationUiTest';

function shouldRegisterAbilityRestartIsolation(): boolean {
  const selectedClass: string = abilityDelegatorRegistry.getArguments().parameters['-s class'] ?? '';
  return selectedClass === ABILITY_RESTART_ISOLATION_CLASS ||
    selectedClass.startsWith(`${ABILITY_RESTART_ISOLATION_CLASS}#`);
}

export default function testsuite() {
  if (shouldRegisterAbilityRestartIsolation()) {
    abilityRestartIsolationTest();
  }
  businessLifecycleStopReproTest();
  directMountTest();
  mainPageTest();
  mainPageStressTest();
  registerMainPageSpecs();
  mockKitTest();
  registerNetworkSpecs();
  registerNetworkListSpecs();
  registerNavigationSpecs();
  registerDemoPagesSpecs();
  registerLifecycleStressSpecs();
  stateLeakDiagnosticTest();
}
