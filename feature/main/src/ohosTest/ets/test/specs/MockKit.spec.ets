import { ArgumentMatchers, expect, it, MockKit, when } from '@ohos/hypium';

class MockPayload {
  readonly name: string;

  constructor(name: string) {
    this.name = name;
  }
}

class MockApiService {
  savedValue: string = '';

  getLabel(id: string): string {
    return `real-${id}`;
  }

  getAny(value: string): string {
    return `real-${value}`;
  }

  getNumber(value: number): string {
    return `real-${value}`;
  }

  getBoolean(value: boolean): string {
    return `real-${value}`;
  }

  getObject(value: MockPayload): string {
    return `real-${value.name}`;
  }

  runCallback(callback: () => string): string {
    return callback();
  }

  save(value: string): void {
    this.savedValue = value;
  }

  async fetch(id: string): Promise<string> {
    return Promise.resolve(`real-${id}`);
  }
}

class OwnMethodService {
  format: (value: string) => string;

  constructor() {
    this.format = this.formatValue;
  }

  private formatValue(value: string): string {
    return `real-${value}`;
  }
}

export function registerMockKitSpecs(): void {
  it('mockKitReturnsValuesForExactArguments', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const getLabel: Function = mocker.mockFunc(service, service.getLabel);
    when(getLabel)('goods-1').afterReturn('Mock 商品');

    try {
      expect(service.getLabel('goods-1')).assertEqual('Mock 商品');
      mocker.verify('getLabel', ['goods-1']).once();
      mocker.verify('getLabel', ['goods-2']).never();
    } finally {
      mocker.clear(service);
    }
  });

  it('mockKitRunsActionsAndVerifiesInvocationCounts', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const getLabel: Function = mocker.mockFunc(service, service.getLabel);
    when(getLabel)(ArgumentMatchers.anyString).afterAction((id: string): string => `action-${id}`);

    try {
      expect(service.getLabel('first')).assertEqual('action-first');
      expect(service.getLabel('first')).assertEqual('action-first');
      mocker.verify('getLabel', ['first']).times(2);
      mocker.verify('getLabel', ['first']).atLeast(1);
      mocker.verify('getLabel', ['first']).atMost(2);
    } finally {
      mocker.clear(service);
    }
  });

  it('mockKitSupportsTypedAndRegexArgumentMatchers', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const getAny: Function = mocker.mockFunc(service, service.getAny);
    const getLabel: Function = mocker.mockFunc(service, service.getLabel);
    const getNumber: Function = mocker.mockFunc(service, service.getNumber);
    const getBoolean: Function = mocker.mockFunc(service, service.getBoolean);
    const getObject: Function = mocker.mockFunc(service, service.getObject);
    const runCallback: Function = mocker.mockFunc(service, service.runCallback);
    when(getAny)(ArgumentMatchers.any).afterReturn('any');
    when(getLabel)(ArgumentMatchers.matchRegexs(/^goods-\d+$/)).afterReturn('regex');
    when(getNumber)(ArgumentMatchers.anyNumber).afterReturn('number');
    when(getBoolean)(ArgumentMatchers.anyBoolean).afterReturn('boolean');
    when(getObject)(ArgumentMatchers.anyObj).afterReturn('object');
    when(runCallback)(ArgumentMatchers.anyFunction).afterReturn('function');

    try {
      expect(service.getAny('anything')).assertEqual('any');
      expect(service.getLabel('goods-42')).assertEqual('regex');
      expect(service.getNumber(42)).assertEqual('number');
      expect(service.getBoolean(true)).assertEqual('boolean');
      expect(service.getObject(new MockPayload('payload'))).assertEqual('object');
      expect(service.runCallback((): string => 'real callback')).assertEqual('function');
    } finally {
      mocker.clear(service);
    }
  });

  it('mockKitReturnsNothingForVoidMethods', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const save: Function = mocker.mockFunc(service, service.save);
    when(save)(ArgumentMatchers.anyString).afterReturnNothing();

    try {
      service.save('ignored');
      expect(service.savedValue).assertEqual('');
      mocker.verify('save', ['ignored']).once();
    } finally {
      mocker.clear(service);
    }
  });

  it('mockKitThrowsConfiguredFailures', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const getLabel: Function = mocker.mockFunc(service, service.getLabel);
    when(getLabel)('broken').afterThrow('mock failure');
    let thrownValue: string = '';

    try {
      service.getLabel('broken');
    } catch (error) {
      thrownValue = `${error}`;
    } finally {
      mocker.clear(service);
    }

    expect(thrownValue).assertEqual('mock failure');
  });

  it('mockKitRejectsAsyncRequests', 0, async () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const fetch: Function = mocker.mockFunc(service, service.fetch);
    when(fetch)('offline').afterReturn(Promise.reject(new Error('network unavailable')));
    let errorMessage: string = '';

    try {
      await service.fetch('offline');
    } catch (error) {
      const reason: Error = error as Error;
      errorMessage = reason.message;
    } finally {
      mocker.clear(service);
    }

    expect(errorMessage).assertEqual('network unavailable');
  });

  it('mockKitCreatesMocksFromOwnObjectMethods', 0, () => {
    const mocker: MockKit = new MockKit();
    const mockedService: OwnMethodService = mocker.mockObject(new OwnMethodService()) as OwnMethodService;
    const format: Function = mockedService.format;
    when(format)(ArgumentMatchers.anyString).afterReturn('mock object');

    expect(mockedService.format('value')).assertEqual('mock object');
    mocker.verify('formatValue', ['value']).once();
  });

  it('mockKitCanRestoreOneOrAllMockedMethods', 0, () => {
    const ignoreMocker: MockKit = new MockKit();
    const ignoredService: MockApiService = new MockApiService();
    const ignoredGetLabel: Function = ignoreMocker.mockFunc(ignoredService, ignoredService.getLabel);
    when(ignoredGetLabel)(ArgumentMatchers.anyString).afterReturn('mocked');
    expect(ignoredService.getLabel('one')).assertEqual('mocked');
    ignoreMocker.ignoreMock(ignoredService, ignoredGetLabel);
    expect(ignoredService.getLabel('one')).assertEqual('real-one');

    const clearMocker: MockKit = new MockKit();
    const clearedService: MockApiService = new MockApiService();
    const clearedGetLabel: Function = clearMocker.mockFunc(clearedService, clearedService.getLabel);
    when(clearedGetLabel)(ArgumentMatchers.anyString).afterReturn('mocked');
    expect(clearedService.getLabel('two')).assertEqual('mocked');
    clearMocker.clear(clearedService);
    expect(clearedService.getLabel('two')).assertEqual('real-two');
  });

  it('mockKitCanModelSequentialResultsWithAnAction', 0, () => {
    const mocker: MockKit = new MockKit();
    const service: MockApiService = new MockApiService();
    const getLabel: Function = mocker.mockFunc(service, service.getLabel);
    let requestCount: number = 0;
    when(getLabel)(ArgumentMatchers.anyString).afterAction((_id: string): string => {
      requestCount += 1;
      return requestCount === 1 ? 'first result' : 'later result';
    });

    try {
      expect(service.getLabel('same-id')).assertEqual('first result');
      expect(service.getLabel('same-id')).assertEqual('later result');
      mocker.verify('getLabel', ['same-id']).times(2);
    } finally {
      mocker.clear(service);
    }
  });
}
