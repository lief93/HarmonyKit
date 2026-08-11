import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { afterAll, beforeAll, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { GoodsRepository, GoodsRepositoryProvider } from 'data';
import { Goods, NetworkResponse } from 'model';
import { DemoNavigator } from 'navigation';
import { MountedComponent, mountComponent } from '../framework/ComponentMount';
import { createDeferred, Deferred } from '../framework/Deferred';
import { requireText, requireTextAbsent } from '../framework/UiDriver';
import { NavigationPageRobot } from '../robots/NavigationPageRobot';
import { NetworkPageRobot } from '../robots/NetworkPageRobot';
import { createMockGoodsResponse } from '../support/GoodsFixtures';
import { launchHost } from '../support/HarmonyKitTestApp';
import { MAIN_CARD, NETWORK_PAGE_TITLE, START_TIMEOUT } from '../support/TestValues';

const TAG: string = 'StateLeakDiagnostic';
const LOG_PREFIX: string = '[STATE-LEAK-DIAG]';
const ENTRY_ABILITY_NAME: string = 'EntryAbility';
const ENTRY_MODULE_NAME: string = 'entry';
const TEST_ABILITY_NAME: string = 'TestAbility';
const TEST_MODULE_NAME: string = 'main_test';
const LEAKED_OVERLAY_TEXT: string = 'Overlay retained from previous case';
const MISSING_DRIVER_PROBE_TEXT: string = 'State leak driver probe must stay missing';

let entryGeneration: number = 0;
let activeCase: string = 'suite-setup';
let pendingRequest: Deferred<NetworkResponse<Goods>> | undefined;
let pendingResponse: NetworkResponse<Goods> | undefined;
let pendingMocker: MockKit | undefined;
let pendingRepository: GoodsRepository | undefined;
let leakedMount: MountedComponent | undefined;
let callbackRelease: Deferred<boolean> | undefined;
let leakedTask: Promise<void> | undefined;
let callbackObservedCase: string = '';
let driverTaskRelease: Deferred<boolean> | undefined;
let leakedDriverTask: Promise<void> | undefined;
let leakedDriverOutcome: string = '';
let currentDriverOutcome: string = '';

function logEvent(event: string): void {
  hilog.info(
    0x0000,
    TAG,
    '%{public}s case=%{public}s generation=%{public}d event=%{public}s',
    LOG_PREFIX,
    activeCase,
    entryGeneration,
    event
  );
}

function startCase(name: string): void {
  activeCase = name;
  logEvent('case-start');
}

function finishCase(): void {
  logEvent('case-finish');
}

function requirePendingRequest(): Deferred<NetworkResponse<Goods>> {
  if (pendingRequest === undefined) {
    throw new Error('pending request from the previous case is missing');
  }
  return pendingRequest;
}

function requirePendingResponse(): NetworkResponse<Goods> {
  if (pendingResponse === undefined) {
    throw new Error('pending response from the previous case is missing');
  }
  return pendingResponse;
}

function requirePendingRepository(): GoodsRepository {
  if (pendingRepository === undefined) {
    throw new Error('repository from the previous case is missing');
  }
  return pendingRepository;
}

async function openAnotherPendingNetworkPage(driver: Driver): Promise<void> {
  const repository: GoodsRepository = requirePendingRepository();
  await launchHost(driver);
  expect(GoodsRepositoryProvider.get() === repository).assertTrue();
  DemoNavigator.toNetworkDemo();
  await requireText(driver, NETWORK_PAGE_TITLE, START_TIMEOUT);
  const page: NetworkPageRobot = new NetworkPageRobot(driver);
  await page.expectLoading();
}

function cleanupPendingNetwork(): void {
  if (pendingRequest !== undefined && pendingResponse !== undefined) {
    pendingRequest.resolve(pendingResponse);
  }
  GoodsRepositoryProvider.reset();
  if (pendingMocker !== undefined && pendingRepository !== undefined) {
    pendingMocker.clear(pendingRepository);
  }
  pendingRequest = undefined;
  pendingResponse = undefined;
  pendingMocker = undefined;
  pendingRepository = undefined;
}

async function runLeakedTask(release: Deferred<boolean>): Promise<void> {
  await release.promise;
  callbackObservedCase = activeCase;
  logEvent('callback-created-by-previous-case-fired');
}

async function runLeakedDriverTask(release: Deferred<boolean>, driver: Driver): Promise<void> {
  await release.promise;
  logEvent('previous-case-driver-call-start');
  try {
    await driver.waitForComponent(ON.text(MISSING_DRIVER_PROBE_TEXT), 1500);
    leakedDriverOutcome = 'completed';
  } catch (error) {
    leakedDriverOutcome = `error:${String(error)}`;
  }
  logEvent(`previous-case-driver-call-finish:${leakedDriverOutcome}`);
}

@ComponentV2
struct LeakedOverlayHost {
  build() {
    Column() {
      Text(LEAKED_OVERLAY_TEXT)
        .fontSize(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
  }
}

@Builder
function buildLeakedOverlay(): void {
  LeakedOverlayHost();
}

export default function stateLeakDiagnosticTest(): void {
  describe('StateLeakDiagnosticUiTest', () => {
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const entryMonitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: ENTRY_ABILITY_NAME,
      moduleName: ENTRY_MODULE_NAME,
      onAbilityCreate: (_ability: UIAbility): void => {
        entryGeneration += 1;
        logEvent('EntryAbility-create');
      },
      onAbilityDestroy: (_ability: UIAbility): void => {
        logEvent('EntryAbility-destroy');
      }
    };
    const testMonitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: TEST_ABILITY_NAME,
      moduleName: TEST_MODULE_NAME,
      onAbilityDestroy: (_ability: UIAbility): void => {
        logEvent('TestAbility-destroy');
      }
    };

    beforeAll(async () => {
      await delegator.addAbilityMonitor(entryMonitor);
      await delegator.addAbilityMonitor(testMonitor);
      logEvent('suite-monitors-added');
    });

    afterAll(async () => {
      cleanupPendingNetwork();
      if (callbackRelease !== undefined) {
        callbackRelease.resolve(true);
      }
      if (leakedTask !== undefined) {
        await leakedTask;
      }
      if (driverTaskRelease !== undefined) {
        driverTaskRelease.resolve(true);
      }
      if (leakedDriverTask !== undefined) {
        await leakedDriverTask;
      }
      if (leakedMount !== undefined) {
        leakedMount.unmount();
        leakedMount = undefined;
      }
      await delegator.removeAbilityMonitor(entryMonitor);
      await delegator.removeAbilityMonitor(testMonitor);
      logEvent('suite-cleanup-finished');
    });

    it('leavesPendingNetworkPageGeneration1', 0, async () => {
      startCase('leavesPendingNetworkPageGeneration1');
      pendingMocker = new MockKit();
      pendingRepository = new GoodsRepository();
      const getGoodsInfo: Function = pendingMocker.mockFunc(
        pendingRepository,
        pendingRepository.getGoodsInfo
      );
      pendingRequest = createDeferred<NetworkResponse<Goods>>();
      pendingResponse = createMockGoodsResponse();
      when(getGoodsInfo)('1').afterReturn(pendingRequest.promise);
      GoodsRepositoryProvider.set(pendingRepository);

      const driver: Driver = Driver.create();
      const page: NetworkPageRobot = new NetworkPageRobot(driver);
      await page.openDirectly();
      await page.expectLoading();
      finishCase();
    });

    it('leavesPendingNetworkPageGeneration2', 0, async () => {
      startCase('leavesPendingNetworkPageGeneration2');
      await openAnotherPendingNetworkPage(Driver.create());
      finishCase();
    });

    it('leavesPendingNetworkPageGeneration3', 0, async () => {
      startCase('leavesPendingNetworkPageGeneration3');
      await openAnotherPendingNetworkPage(Driver.create());
      finishCase();
    });

    it('leavesPendingNetworkPageGeneration4', 0, async () => {
      startCase('leavesPendingNetworkPageGeneration4');
      await openAnotherPendingNetworkPage(Driver.create());
      finishCase();
    });

    it('resolvesCallbacksOwnedByDestroyedPages', 0, async () => {
      startCase('resolvesCallbacksOwnedByDestroyedPages');
      const request: Deferred<NetworkResponse<Goods>> = requirePendingRequest();
      const response: NetworkResponse<Goods> = requirePendingResponse();
      const page: NetworkPageRobot = new NetworkPageRobot(Driver.create());

      try {
        request.resolve(response);
        await page.expectMockData();
        await page.expectLoadingAbsent();
      } finally {
        cleanupPendingNetwork();
      }
      finishCase();
    });

    it('leavesMountedOverlayInAbilityWindow', 0, async () => {
      startCase('leavesMountedOverlayInAbilityWindow');
      const driver: Driver = Driver.create();
      await launchHost(driver);
      const topAbility: UIAbility = await delegator.getCurrentTopAbility();
      leakedMount = await mountComponent(topAbility, wrapBuilder(buildLeakedOverlay));
      await requireText(driver, LEAKED_OVERLAY_TEXT, START_TIMEOUT);
      finishCase();
    });

    it('detectsAndRemovesOverlayFromPreviousCase', 0, async () => {
      startCase('detectsAndRemovesOverlayFromPreviousCase');
      const driver: Driver = Driver.create();
      await requireText(driver, LEAKED_OVERLAY_TEXT, START_TIMEOUT);
      if (leakedMount === undefined) {
        throw new Error('mounted overlay from the previous case is missing');
      }
      leakedMount.unmount();
      leakedMount = undefined;
      await requireTextAbsent(driver, LEAKED_OVERLAY_TEXT);
      finishCase();
    });

    it('leavesDeepNavigationRoute', 0, async () => {
      startCase('leavesDeepNavigationRoute');
      const navigation: NavigationPageRobot = new NavigationPageRobot(Driver.create());
      await navigation.openParameterizedRoute();
      await navigation.expectParameters();
      finishCase();
    });

    it('detectsAndResetsRouteFromPreviousCase', 0, async () => {
      startCase('detectsAndResetsRouteFromPreviousCase');
      const driver: Driver = Driver.create();
      await requireText(driver, '10001', START_TIMEOUT);
      await driver.pressBack();
      await requireText(driver, '导航拦截', START_TIMEOUT);
      finishCase();
    });

    it('startsAsyncWorkWithoutAwaitingIt', 0, async () => {
      startCase('startsAsyncWorkWithoutAwaitingIt');
      callbackObservedCase = '';
      callbackRelease = createDeferred<boolean>();
      leakedTask = runLeakedTask(callbackRelease);
      finishCase();
    });

    it('observesPreviousCaseCallbackRunningInCurrentCase', 0, async () => {
      startCase('observesPreviousCaseCallbackRunningInCurrentCase');
      if (callbackRelease === undefined || leakedTask === undefined) {
        throw new Error('background task from the previous case is missing');
      }
      callbackRelease.resolve(true);
      await leakedTask;
      expect(callbackObservedCase).assertEqual('observesPreviousCaseCallbackRunningInCurrentCase');
      callbackRelease = undefined;
      leakedTask = undefined;
      finishCase();
    });

    it('startsDriverCallOwnedByPreviousCase', 0, async () => {
      startCase('startsDriverCallOwnedByPreviousCase');
      const driver: Driver = Driver.create();
      await launchHost(driver);
      await requireText(driver, MAIN_CARD, START_TIMEOUT);
      leakedDriverOutcome = '';
      currentDriverOutcome = '';
      driverTaskRelease = createDeferred<boolean>();
      leakedDriverTask = runLeakedDriverTask(driverTaskRelease, driver);
      finishCase();
    });

    it('probesConcurrentDriverCallFromPreviousCase', 0, async () => {
      startCase('probesConcurrentDriverCallFromPreviousCase');
      if (driverTaskRelease === undefined || leakedDriverTask === undefined) {
        throw new Error('driver task from the previous case is missing');
      }
      driverTaskRelease.resolve(true);
      await Promise.resolve(true);

      try {
        await Driver.create().waitForComponent(ON.text(MISSING_DRIVER_PROBE_TEXT), 1500);
        currentDriverOutcome = 'completed';
      } catch (error) {
        currentDriverOutcome = `error:${String(error)}`;
      }
      await leakedDriverTask;
      logEvent(`concurrent-driver-outcomes:old=${leakedDriverOutcome},current=${currentDriverOutcome}`);
      expect(leakedDriverOutcome.length > 0).assertTrue();
      expect(currentDriverOutcome.length > 0).assertTrue();
      driverTaskRelease = undefined;
      leakedDriverTask = undefined;
      finishCase();
    });

    it('reachesCleanFollowerAfterAllLeakScenarios', 0, async () => {
      startCase('reachesCleanFollowerAfterAllLeakScenarios');
      const driver: Driver = Driver.create();
      await launchHost(driver);
      await requireText(driver, MAIN_CARD, START_TIMEOUT);
      await requireTextAbsent(driver, LEAKED_OVERLAY_TEXT);
      finishCase();
    });
  });
}
