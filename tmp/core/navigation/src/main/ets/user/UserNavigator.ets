import { navigateTo } from "../NavigationService";
import { UserRoutes } from "./UserRoutes";

/**
 * @file 用户模块导航封装
 * @author Joker.X
 */
export class UserNavigator {
  /**
   * 跳转到个人中心
   * @returns {void} 无返回值
   */
  static toProfile(): void {
    navigateTo(UserRoutes.Profile);
  }
}
