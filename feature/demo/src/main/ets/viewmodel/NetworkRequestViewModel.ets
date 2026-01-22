import { BaseViewModel } from "@core/base";
import { GoodsRepository } from "@foundation/repository";
import { Goods, GoodsSearchRequest } from "@foundation/biz-model";
import { NetworkPageData } from "@core/model";
import { RequestHelper } from "@core/result";
import { ToastUtils } from "@core/util";

/**
 * @file 通用网络请求示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class NetworkRequestViewModel extends BaseViewModel {
  /**
   * GET 请求加载状态
   */
  @Trace
  getLoading: boolean = false;
  /**
   * POST 请求加载状态
   */
  @Trace
  postLoading: boolean = false;
  /**
   * 商品仓库
   */
  private repository: GoodsRepository = new GoodsRepository();

  /**
   * 发起 GET 请求（商品详情）
   */
  requestGoodsDetail() {
    RequestHelper.repository<Goods>(this.repository.getGoodsInfo("1"))
      .start((): void => {
        this.getLoading = true;
      })
      .execute()
      .then((data: Goods): void => {
        const goods: Goods = new Goods(data);
        ToastUtils.showSuccess($r("app.string.demo_network_request_get_success", goods.title));
      })
      .finally((): void => {
        this.getLoading = false;
      });
  }

  /**
   * 发起 POST 请求（商品列表）
   */
  requestGoodsList() {
    const params: GoodsSearchRequest = new GoodsSearchRequest();
    params.page = 1;
    params.size = 20;
    RequestHelper.repository<NetworkPageData<Goods>>(this.repository.getGoodsPage(params))
      .start((): void => {
        this.postLoading = true;
      })
      .execute()
      .then((): void => {
        ToastUtils.showSuccess($r("app.string.demo_network_request_post_success"));
      })
      .finally((): void => {
        this.postLoading = false;
      });
  }
}
