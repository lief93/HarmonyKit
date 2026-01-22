import { BaseNetWorkListViewModel } from "@core/base";
import { GoodsRepository } from "@foundation/repository";
import { Goods, GoodsSearchRequest } from "@foundation/biz-model";
import { NetworkPageData, NetworkResponse } from "@core/model";

/**
 * @file Network List Demo 示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class NetworkListDemoViewModel extends BaseNetWorkListViewModel<Goods> {
  /**
   * 商品仓库
   */
  private repository: GoodsRepository = new GoodsRepository();

  /**
   * 请求商品分页数据
   * @returns {Promise<NetworkResponse<NetworkPageData<Goods>>>} 网络请求 Promise
   */
  protected requestListData(): Promise<NetworkResponse<NetworkPageData<Goods>>> {
    const request: GoodsSearchRequest = new GoodsSearchRequest();
    request.page = this.currentPage;
    request.size = this.pageSize;
    return this.repository.getGoodsPage(request);
  }
}
