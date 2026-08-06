import { Driver } from '@kit.TestKit';
import { ArgumentMatchers, expect, it, MockKit, when } from '@ohos/hypium';
import { GoodsRepository, GoodsRepositoryProvider } from 'data';
import { Goods, NetworkResponse } from 'model';
import { createDeferred, Deferred } from '../framework/Deferred';
import { NetworkPageRobot } from '../robots/NetworkPageRobot';
import { createBusinessErrorResponse, createMockGoodsResponse } from '../support/GoodsFixtures';

export function registerNetworkSpecs(): void {
  it('opensNetworkPageAndReturns', 0, async () => {
    const driver: Driver = Driver.create();
    const page: NetworkPageRobot = new NetworkPageRobot(driver);
    await page.openFromMain();

    await page.returnToMain();
  });

  it('showsMockedNetworkData', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
    const response: NetworkResponse<Goods> = createMockGoodsResponse();
    when(getGoodsInfo)('1').afterReturn(Promise.resolve(response));
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkPageRobot = new NetworkPageRobot(driver);
      await page.openFromMain();

      await page.expectMockData();
    } finally {
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });

  it('showsLoadingUntilMockedNetworkCompletes', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
    const pendingRequest: Deferred<NetworkResponse<Goods>> = createDeferred<NetworkResponse<Goods>>();
    const response: NetworkResponse<Goods> = createMockGoodsResponse();
    when(getGoodsInfo)('1').afterReturn(pendingRequest.promise);
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkPageRobot = new NetworkPageRobot(driver);
      await page.openDirectly();

      await page.expectLoading();
      await page.expectMockTitleAbsent();

      pendingRequest.resolve(response);

      await page.expectMockData();
      await page.waitForStateChange();
      await page.expectLoadingAbsent();
    } finally {
      pendingRequest.resolve(response);
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });

  it('showsErrorWhenMockedNetworkRejects', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
    when(getGoodsInfo)('1').afterReturn(Promise.reject(new Error('Mock transport failure')));
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkPageRobot = new NetworkPageRobot(driver);
      await page.openDirectly();

      await page.expectError();
      mocker.verify('getGoodsInfo', ['1']).once();
    } finally {
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });

  it('retriesMockedBusinessFailureAndShowsData', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsInfo: Function = mocker.mockFunc(repository, repository.getGoodsInfo);
    const response: NetworkResponse<Goods> = createMockGoodsResponse();
    let requestCount: number = 0;
    when(getGoodsInfo)(ArgumentMatchers.anyString)
      .afterAction((_id: string): Promise<NetworkResponse<Goods>> => {
        requestCount += 1;
        return requestCount === 1
          ? Promise.resolve(createBusinessErrorResponse())
          : Promise.resolve(response);
      });
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkPageRobot = new NetworkPageRobot(driver);
      await page.openDirectly();

      await page.expectError();
      await page.retry();
      await page.waitForStateChange();
      expect(requestCount).assertEqual(2);
      await page.expectMockData();
      await page.expectLoadingAbsent();
      mocker.verify('getGoodsInfo', ['1']).times(2);
    } finally {
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });
}
