import { navigateTo } from "../NavigationService";
import { MainRoutes } from "./MainRoutes";

/**
 * @file 主模块导航封装
 * @author Joker.X
 */
export class MainNavigator {
  /**
   * 跳转到主框架
   * @returns {void} 无返回值
   */
  static toMain(): void {
    navigateTo(MainRoutes.Main);
  }
}
