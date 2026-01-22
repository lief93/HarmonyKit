import { RouteBuild, RouteGraph } from "navigation";
import { MainRoutes } from "navigation/src/main/ets/main/MainRoutes";
import { MainNav } from "./MainNav";

/**
 * @file 主模块导航图
 * @author Joker.X
 */
export class MainGraph implements RouteGraph {
  /**
   * 注册主模块导航路由
   * @returns {void} 无返回值
   */
  register(): void {
    RouteBuild.register(MainRoutes.Main, wrapBuilder(MainNav));
  }
}
