import { BaseNetWorkViewModel } from "base";
import { GoodsRepository } from "data";
import { Goods, NetworkResponse } from "model";

/**
 * @file Network Demo 示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class NetworkDemoViewModel extends BaseNetWorkViewModel<Goods> {
  /**
   * 商品仓库
   */
  private repository: GoodsRepository = new GoodsRepository();

  /**
   * 请求商品详情数据
   * @returns {Promise<NetworkResponse<Goods>>} 网络请求 Promise
   */
  protected requestRepository(): Promise<NetworkResponse<Goods>> {
    return this.repository.getGoodsInfo("1");
  }
}
