import { BaseNetWorkViewModel, LifecycleFaultInjection } from "base";
import { GoodsRepository, GoodsRepositoryProvider } from "data";
import { Goods, NetworkResponse } from "model";

/**
 * @file Network Demo 示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class NetworkDemoViewModel extends BaseNetWorkViewModel<Goods> {
  private pageVisible: boolean = false;
  private staleBusinessTaskId: number = -1;

  /**
   * 商品仓库
   */
  private repository: GoodsRepository = GoodsRepositoryProvider.get();

  aboutToAppear(): void {
    this.pageVisible = true;
    super.aboutToAppear();
    if (!LifecycleFaultInjection.shouldCrashFromStaleCallback()) {
      return;
    }
    this.staleBusinessTaskId = setTimeout((): void => {
      this.staleBusinessTaskId = -1;
      if (!this.pageVisible && LifecycleFaultInjection.shouldCrashFromStaleCallback()) {
        throw new Error('stale NetworkDemo business callback fired after page exit');
      }
    }, 3000);
    LifecycleFaultInjection.recordStaleCallbackScheduled();
  }

  aboutToDisappear(): void {
    this.pageVisible = false;
    this.reset();
    super.aboutToDisappear();
  }

  /**
   * 重置页面持有的业务状态和异步任务。
   * @returns {void} 无返回值
   */
  reset(): void {
    if (this.staleBusinessTaskId !== -1) {
      clearTimeout(this.staleBusinessTaskId);
      this.staleBusinessTaskId = -1;
      LifecycleFaultInjection.recordStaleCallbackCleared();
    }
  }

  /**
   * 请求商品详情数据
   * @returns {Promise<NetworkResponse<Goods>>} 网络请求 Promise
   */
  protected requestRepository(): Promise<NetworkResponse<Goods>> {
    return this.repository.getGoodsInfo("1");
  }
}
