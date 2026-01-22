import { RouteBuild, RouteGraph } from "@core/navigation";
import { AuthRoutes } from "@foundation/biz-navigation/src/main/ets/auth/AuthRoutes";
import { LoginNav } from "./LoginNav";

/**
 * @file 认证模块导航图
 * @author Joker.X
 */
export class AuthGraph implements RouteGraph {
  /**
   * 注册认证模块导航路由
   * @returns {void} 无返回值
   */
  register(): void {
    RouteBuild.register(AuthRoutes.Login, wrapBuilder(LoginNav));
  }
}
