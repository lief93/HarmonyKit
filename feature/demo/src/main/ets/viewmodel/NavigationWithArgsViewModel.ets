import { BaseViewModel } from "@core/base";
import { getRouteParams } from "@foundation/biz-navigation";
import { DemoGoodsParam } from "@foundation/biz-navigation/src/main/ets/demo/DemoParam";
import { DemoRoutes } from "@foundation/biz-navigation/src/main/ets/demo/DemoRoutes";

/**
 * @file 带参跳转示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class NavigationWithArgsViewModel extends BaseViewModel {
  /**
   * 获取路由参数
   */
  routeParams: DemoGoodsParam = getRouteParams<DemoGoodsParam>(DemoRoutes.NavigationWithArgs);
}
