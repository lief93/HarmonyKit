import { navigateTo, navigateToForResult } from "../NavigationService";
import { DemoRoutes } from "./DemoRoutes";
import { DemoGoodsParam } from "./DemoParam";
import type { DemoResult } from "./DemoResult";

/**
 * @file Demo 模块导航封装
 * @author Joker.X
 */
export class DemoNavigator {
  /**
   * 跳转到 Network Demo 示例页
   * @returns {void} 无返回值
   */
  static toNetworkDemo(): void {
    navigateTo(DemoRoutes.NetworkDemo);
  }

  /**
   * 跳转到 Network List Demo 示例页
   * @returns {void} 无返回值
   */
  static toNetworkListDemo(): void {
    navigateTo(DemoRoutes.NetworkListDemo);
  }

  /**
   * 跳转到数据库示例页
   * @returns {void} 无返回值
   */
  static toDatabase(): void {
    navigateTo(DemoRoutes.Database);
  }

  /**
   * 跳转到本地存储示例页
   * @returns {void} 无返回值
   */
  static toLocalStorage(): void {
    navigateTo(DemoRoutes.LocalStorage);
  }

  /**
   * 跳转到状态管理示例页
   * @returns {void} 无返回值
   */
  static toStateManagement(): void {
    navigateTo(DemoRoutes.StateManagement);
  }

  /**
   * 跳转到通用网络请求示例页
   * @returns {void} 无返回值
   */
  static toNetworkRequest(): void {
    navigateTo(DemoRoutes.NetworkRequest);
  }

  /**
   * 跳转到带参跳转示例页
   * @param {number} goodsId - 商品 ID
   * @param {Resource} goodsName - 商品名称
   * @returns {void} 无返回值
   */
  static toNavigationWithArgs(goodsId: number, goodsName: Resource): void {
    const params: DemoGoodsParam = { goodsId, goodsName };
    navigateTo(DemoRoutes.NavigationWithArgs, params);
  }

  /**
   * 跳转到结果回传示例页
   * @returns {Promise<DemoResult | undefined>} 返回结果 Promise
   */
  static toNavigationResult(): Promise<DemoResult | undefined> {
    return navigateToForResult<DemoResult>(DemoRoutes.NavigationResult);
  }

  /**
   * 跳转到安全区示例页
   * @returns {void} 无返回值
   */
  static toSafeAreaDemo(): void {
    navigateTo(DemoRoutes.SafeAreaDemo);
  }

  /**
   * 跳转到屏幕适配示例页
   * @returns {void} 无返回值
   */
  static toScreenAdaptDemo(): void {
    navigateTo(DemoRoutes.ScreenAdaptDemo);
  }
}
