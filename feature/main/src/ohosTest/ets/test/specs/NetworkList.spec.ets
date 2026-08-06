import { Driver } from '@kit.TestKit';
import { ArgumentMatchers, it, MockKit, when } from '@ohos/hypium';
import { GoodsRepository, GoodsRepositoryProvider } from 'data';
import { Goods, GoodsSearchRequest, NetworkPageData, NetworkResponse } from 'model';
import { NetworkListPageRobot } from '../robots/NetworkListPageRobot';
import { createEmptyGoodsPageResponse, createMockGoodsPageResponse } from '../support/GoodsFixtures';

export function registerNetworkListSpecs(): void {
  it('showsEmptyStateForMockedListResponse', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsPage: Function = mocker.mockFunc(repository, repository.getGoodsPage);
    const response: NetworkResponse<NetworkPageData<Goods>> = createEmptyGoodsPageResponse();
    when(getGoodsPage)(ArgumentMatchers.anyObj).afterReturn(Promise.resolve(response));
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkListPageRobot = new NetworkListPageRobot(driver);
      await page.openDirectly();

      await page.expectTitle();
      await page.expectEmpty();
      mocker.verify('getGoodsPage', [new GoodsSearchRequest()]).once();
    } finally {
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });

  it('showsDataForMockedListResponse', 0, async () => {
    const mocker: MockKit = new MockKit();
    const repository: GoodsRepository = new GoodsRepository();
    const getGoodsPage: Function = mocker.mockFunc(repository, repository.getGoodsPage);
    const response: NetworkResponse<NetworkPageData<Goods>> = createMockGoodsPageResponse();
    when(getGoodsPage)(ArgumentMatchers.anyObj).afterReturn(Promise.resolve(response));
    GoodsRepositoryProvider.set(repository);

    try {
      const driver: Driver = Driver.create();
      const page: NetworkListPageRobot = new NetworkListPageRobot(driver);
      await page.openDirectly();

      await page.expectMockData();
      mocker.verify('getGoodsPage', [new GoodsSearchRequest()]).once();
    } finally {
      GoodsRepositoryProvider.reset();
      mocker.clear(repository);
    }
  });
}
