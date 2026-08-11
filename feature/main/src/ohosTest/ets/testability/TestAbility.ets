import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';

const TAG: string = 'HarmonyKitTestRunner';
const TIMEOUT_KEY: string = '-s timeout';
const MIN_CASE_TIMEOUT_MS: number = 300000;
const ON_DESTROY_ERROR: number = -2;

export default class TestAbility extends UIAbility {
  private readonly abilityDelegator: abilityDelegatorRegistry.AbilityDelegator;

  constructor() {
    super();
    this.abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const args: abilityDelegatorRegistry.AbilityDelegatorArgs = abilityDelegatorRegistry.getArguments();
    const configuredTimeout: number = Number(args.parameters[TIMEOUT_KEY] ?? '0');
    if (configuredTimeout < MIN_CASE_TIMEOUT_MS) {
      args.parameters[TIMEOUT_KEY] = MIN_CASE_TIMEOUT_MS.toString();
    }

    hilog.info(
      0x0000,
      TAG,
      'TestAbility starts Hypium, timeout=%{public}s',
      args.parameters[TIMEOUT_KEY]
    );
    Hypium.hypiumTest(this.abilityDelegator, args, testsuite);
  }

  onDestroy(): void {
    hilog.error(0x0000, TAG, '%{public}s', 'TestAbility destroyed before Hypium finished');
    this.abilityDelegator.finishTest(
      'TestAbility destroyed before Hypium finished',
      ON_DESTROY_ERROR,
      (): void => {}
    );
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('testability/pages/Index', (error): void => {
      if (error.code) {
        hilog.error(0x0000, TAG, 'load test window failed: %{public}s', JSON.stringify(error));
      }
    });
  }
}
