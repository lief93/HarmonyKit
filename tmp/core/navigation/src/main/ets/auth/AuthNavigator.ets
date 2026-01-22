import { navigateTo } from "../NavigationService";
import { AuthRoutes } from "./AuthRoutes";

/**
 * @file 认证模块导航封装
 * @author Joker.X
 */
export class AuthNavigator {
  /**
   * 跳转到登录页面
   * @returns {void} 无返回值
   */
  static toLogin(): void {
    navigateTo(AuthRoutes.Login);
  }
}
