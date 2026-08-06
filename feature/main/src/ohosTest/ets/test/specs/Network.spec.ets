import { Driver } from '@kit.TestKit';
import { it, MockKit, when } from '@ohos/hypium';
import { GoodsRepository, GoodsRepositoryProvider } from 'data';
import { Goods, NetworkResponse } from 'model';
import { createDeferred, Deferred } from '../framework/Deferred';
import { NetworkPageRobot } from '../robots/NetworkPageRobot';
import { createMockGoodsResponse } from '../support/GoodsFixtures';

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
}
