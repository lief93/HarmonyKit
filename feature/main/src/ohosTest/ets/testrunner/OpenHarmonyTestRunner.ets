import { UIAbility, application, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';

let abilityDelegator: abilityDelegatorRegistry.AbilityDelegator;
let abilityDelegatorArguments: abilityDelegatorRegistry.AbilityDelegatorArgs;
const MOCK_CONFIG_PATH: string = 'mock/mock-config.json';
const TAG: string = 'HarmonyKitTestRunner';
const UNLOCK_ERROR: number = -3;

interface MockSource {
  source: string;
}

async function onAbilityCreate(data: UIAbility): Promise<void> {
  hilog.info(0x0000, TAG, 'TestAbility created: %{public}s', JSON.stringify(data));
}

async function onMonitorAdded(error: BusinessError): Promise<void> {
  hilog.info(0x0000, TAG, 'TestAbility monitor added: %{public}s', JSON.stringify(error) ?? '');
}

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'custom runner onPrepare');
  }

  async onRun(): Promise<void> {
    hilog.info(0x0000, TAG, '%{public}s', 'custom runner onRun');
    abilityDelegatorArguments = abilityDelegatorRegistry.getArguments();
    abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    const moduleName: string = abilityDelegatorArguments.parameters['-m'];

    try {
      const context: common.Context = await application.createModuleContext(
        abilityDelegator.getAppContext().getApplicationContext(),
        moduleName
      );
      await startTests(context, moduleName);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      hilog.error(
        0x0000,
        TAG,
        'createModuleContext failed, code: %{public}d, message: %{public}s',
        businessError.code,
        businessError.message
      );
      abilityDelegator.finishTest(businessError.message, businessError.code, (): void => {});
    }
  }
}

async function startTests(context: common.Context, moduleName: string): Promise<void> {
  await configureMocks(context.resourceManager);
  const testAbilityName: string = 'TestAbility';
  const monitor: abilityDelegatorRegistry.AbilityMonitor = {
    abilityName: testAbilityName,
    moduleName: moduleName,
    onAbilityCreate: onAbilityCreate
  };

  await abilityDelegator.addAbilityMonitor(monitor, onMonitorAdded);
  await startTestAbility(
    abilityDelegatorArguments.bundleName,
    testAbilityName,
    moduleName,
    abilityDelegatorArguments.parameters['-D'] === 'true'
  );
}

async function startTestAbility(
  bundleName: string,
  abilityName: string,
  moduleName: string,
  isDebug: boolean
): Promise<void> {
  let command: string = `aa start -b ${bundleName} -a ${abilityName} -m ${moduleName}`;
  if (isDebug) {
    command += ' -D';
  }

  try {
    const result = await abilityDelegator.executeShellCommand(command);
    if (result.stdResult.includes('error: unlock screen failed in developer mode') ||
      result.stdResult.includes('10106102')) {
      abilityDelegator.finishTest(result.stdResult, UNLOCK_ERROR, (): void => {});
    }
  } catch (error) {
    const message: string = String(error);
    hilog.error(0x0000, TAG, 'start TestAbility failed: %{public}s', message);
    abilityDelegator.finishTest(message, UNLOCK_ERROR, (): void => {});
  }
}

async function configureMocks(manager: resourceManager.ResourceManager): Promise<void> {
  try {
    const rawFile: Uint8Array = manager.getRawFileContentSync(MOCK_CONFIG_PATH);
    const mockText: string = util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(rawFile);
    const mockConfig: Record<string, MockSource> = JSON.parse(mockText) as Record<string, MockSource>;
    const mockList: Record<string, string> = {};

    Object.keys(mockConfig).forEach((key: string): void => {
      mockList[key] = mockConfig[key].source;
    });
    abilityDelegator.setMockList(mockList);
  } catch (error) {
    const businessError: BusinessError = error as BusinessError;
    hilog.info(
      0x0000,
      TAG,
      'No usable mock config, code: %{public}d, message: %{public}s',
      businessError.code,
      businessError.message
    );
  }
}
