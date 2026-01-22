import { hilog } from "@kit.PerformanceAnalysisKit";
import { Any } from "@core/model";

const DOMAIN: number = 0;

/**
 * @file 通用导航服务：基于 NavPathStack，提供统一跳转 API
 * @author junbin.yang
 */
export class NavigationService {
  public stack: NavPathStack

  constructor(navStack: NavPathStack) {
    this.stack = navStack
  }

  /**
   * 路由跳转（入栈）
   * @param {string} name - 路由名称
   * @param {Any} [params] - 跳转参数
   * @returns {void} 无返回值
   */
  navigateTo(name: string, params?: Any): void {
    if (!this.stack) {
      return;
    }
    try {
      if (params !== undefined) {
        this.stack.pushPath({
          name: name,
          param: params
        });
        return;
      }
      this.stack.pushPath({
        name: name
      });
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateTo failed: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 返回上一页
   * @returns {void} 无返回值
   */
  navigateBack(): void {
    if (!this.stack) {
      return;
    }
    try {
      this.stack.pop();
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateBack failed: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 携带结果返回上一页（触发上一跳中的 onPop 回调）
   * @param {Any} [result={}] - 返回结果
   * @param {boolean} [animated=true] - 是否需要动画
   * @returns {void} 无返回值
   */
  navigateBackWithResult(result: Any | object = {}, animated?: boolean): void {
    if (!this.stack) {
      return;
    }
    try {
      this.stack.pop(result, animated);
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateBackWithResult failed: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 返回到指定路由
   * @param {string} name - 目标路由名称
   * @param {boolean} inclusive - 是否移除目标自身（默认 false）
   * @returns {void} 无返回值
   */
  popTo(name: string, inclusive: boolean = false): void {
    if (!this.stack) {
      return;
    }
    try {
      this.stack.popToName(name, inclusive);
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] popTo failed: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 跳转并监听返回结果（使用 ArkUI promise 版本 pushDestinationByName）
   * @param {string} name - 路由名称
   * @param {Any} [params] - 跳转参数
   * @param {(info: PopInfo) => void} [onPop] - 返回结果回调（在目标页调用 pop(result) 时触发）
   * @returns {Promise<void>} 跳转完成 Promise
   */
  navigateToWithResult(name: string, params?: Any, onPop?: (info: PopInfo) => void): Promise<void> {
    if (!this.stack) {
      return Promise.resolve();
    }

    const safeParam: Object | undefined = params as Object | undefined;
    try {
      if (onPop) {
        return this.stack.pushDestinationByName(name, safeParam, onPop).catch((err: Any) => {
          hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateToWithResult failed: %{public}s",
            JSON.stringify(err));
        });
      }
      return this.stack.pushDestinationByName(name, safeParam).catch((err: Any) => {
        hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateToWithResult failed: %{public}s", JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] navigateToWithResult failed: %{public}s", JSON.stringify(err));
      return Promise.resolve();
    }
  }

  /**
   * 跳转并以 Promise 形式获取返回结果（上层可 await）
   * @template T
   * @param {string} name - 路由名称
   * @param {Any} [params] - 跳转参数
   * @returns {Promise<T | undefined>} 返回结果（未回传时为 undefined）
   */
  navigateToForResult<T>(name: string, params?: Any): Promise<T | undefined> {
    return new Promise<T | undefined>((resolve) => {
      this.navigateToWithResult(name, params, (info: PopInfo) => {
        resolve(info?.result as T);
      });
    });
  }

  /**
   * 获取指定路由的首个参数（类型安全，屏蔽 unknown）
   * @template T
   * @param {string} name - 路由名称
   * @returns {T} 参数对象；未获取到时返回 undefined
   */
  getRouteParams<T>(name: string): T {
    if (!this.stack) {
      return undefined as T;
    }
    try {
      return this.stack.getParamByName(name)[0] as T;
    } catch (err) {
      hilog.error(DOMAIN, "NavSvc", "[NavigationService] getRouteParams failed: %{public}s", JSON.stringify(err));
      return undefined as T;
    }
  }
}