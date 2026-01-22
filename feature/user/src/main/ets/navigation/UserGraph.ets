import { RouteBuild, RouteGraph } from "@core/navigation";
import { UserRoutes } from "@foundation/biz-navigation/src/main/ets/user/UserRoutes";
import { ProfileNav } from "./ProfileNav";

/**
 * @file 用户模块导航图
 * @author Joker.X
 */
export class UserGraph implements RouteGraph {
  /**
   * 注册用户模块导航路由
   * @returns {void} 无返回值
   */
  register(): void {
    RouteBuild.register(UserRoutes.Profile, wrapBuilder(ProfileNav));
  }
}
