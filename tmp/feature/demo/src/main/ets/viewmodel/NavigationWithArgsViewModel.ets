import { BaseViewModel } from "base";
import { getRouteParams } from "navigation";
import { DemoGoodsParam } from "navigation/src/main/ets/demo/DemoParam";
import { DemoRoutes } from "navigation/src/main/ets/demo/DemoRoutes";

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
