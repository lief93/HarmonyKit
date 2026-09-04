import { BaseViewModel } from "base";
import { navigateBack } from "navigation";

/**
 * @file 轮播组件示例页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class CarouselDemoViewModel extends BaseViewModel {
  /**
   * 返回上一页
   * @returns {void} 无返回值
   */
  onBackClick(): void {
    navigateBack();
  }
}
