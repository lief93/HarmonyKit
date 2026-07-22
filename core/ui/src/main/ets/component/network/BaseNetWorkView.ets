import { BaseNetWorkUiState } from "base";
import { PageLoading } from "../loading/PageLoading";
import { EmptyNetwork } from "../empty/EmptyNetwork";

/**
 * @file 网络请求通用视图组件
 * @author Joker.X
 */
@ComponentV2
export struct BaseNetWorkView {
  /**
   * 当前网络请求 UI 状态
   */
  @Param
  uiState: BaseNetWorkUiState = BaseNetWorkUiState.LOADING;
  /**
   * 错误状态下的重试回调
   */
  @Param
  onRetry: () => void = () => {
  };
  /**
   * 自定义加载内容
   */
  @BuilderParam
  loadingBuilder: CustomBuilder;
  /**
   * 自定义错误内容
   */
  @BuilderParam
  errorBuilder: CustomBuilder;
  /**
   * 成功状态下渲染内容
   */
  @BuilderParam
  content: CustomBuilder;

  /**
   * 默认加载视图
   * @returns {void} 无返回值
   */
  @Builder
  buildDefaultLoading(): void {
    PageLoading();
  }

  /**
   * 默认错误视图
   * @returns {void} 无返回值
   */
  @Builder
  buildDefaultError(): void {
    EmptyNetwork({
      onAction: this.onRetry
    });
  }

  /**
   * 渲染网络请求状态视图
   * @returns {void} 无返回值
   */
  build() {
    Stack() {
      if (this.uiState === BaseNetWorkUiState.LOADING) {
        Column() {
          if (this.loadingBuilder) {
            this.loadingBuilder();
          } else {
            this.buildDefaultLoading();
          }
        }
      } else if (this.uiState === BaseNetWorkUiState.ERROR) {
        Column() {
          if (this.errorBuilder) {
            this.errorBuilder();
          } else {
            this.buildDefaultError();
          }
        }
      } else {
        Column() {
          if (this.content) {
            this.content();
          }
        }
      }
    }
  }
}
