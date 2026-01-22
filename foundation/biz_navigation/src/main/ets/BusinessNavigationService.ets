import { hilog } from "@kit.PerformanceAnalysisKit";
import { getUserState } from "@foundation/biz-state";
import { Any } from "@core/model";
import { requiresLogin, getLoginRoute } from "./RouteInterceptor";
import { NavigationService } from "@core/navigation"

/**
 * @file 全局导航服务：集中存放 NavPathStack，提供统一跳转 API，方便 ViewModel 直接调用
 * @author Joker.X junbin.yang
 */
class BusinessNavigationService extends NavigationService {
  constructor(navStack: NavPathStack) {
    super(navStack);
  }

  navigateTo(name: string, params?: Any): void {
    if (requiresLogin(name)) {
      const userState = getUserState();
      if (!userState.isLoggedIn()) {
        hilog.info(DOMAIN, "NavSvc", `[NavigationService] Intercepting route to ${name}, redirecting to Login`);
        name = getLoginRoute();
      }
    }
    super.navigateTo(name, params);
  }

  navigateToWithResult(name: string, params?: Any, onPop?: (info: PopInfo) => void): Promise<void> {
    if (requiresLogin(name)) {
      const userState = getUserState();
      if (!userState.isLoggedIn()) {
        hilog.info(DOMAIN, "NavSvc", `[NavigationService] Intercepting route to ${name}, redirecting to Login`);
        name = getLoginRoute();
      }
    }
    return super.navigateToWithResult(name, params, onPop);
  }
}

/**
 * Provider / Consumer 共享的键名
 */
export const NAV_PATH_STACK_KEY: string = "navStack";

/**
 * 全局导航栈实例
 */
let globalNavService: BusinessNavigationService | undefined;

const DOMAIN: number = 0;

/**
 * 设置全局导航栈实例（在 NavigationHost aboutToAppear 中调用）
 * @param {NavPathStack} stack - 导航栈实例
 * @returns {void} 无返回值
 */
export function setNavPathStack(stack: NavPathStack): void {
  globalNavService = new BusinessNavigationService(stack);
}

/**
 * 获取当前业务导航栈服务
 * @returns {BusinessNavigationService | undefined} 业务导航服务；未初始化时返回 undefined
 */
function getNavigationService(): BusinessNavigationService | undefined {
  if (!globalNavService) {
    const msg: string = "[NavigationService] nav stack is not initialized, call setNavPathStack first.";
    hilog.error(DOMAIN, "NavSvc", msg);
    return undefined;
  }
  return globalNavService;
}

/**
 * 获取当前导航栈实例
 * @returns {NavPathStack | undefined} 导航栈实例；未初始化时返回 undefined
 */
export function getNavPathStack(): NavPathStack | undefined {
  const service: BusinessNavigationService | undefined = getNavigationService();
  return service?.stack;
}

/**
 * 路由跳转（入栈）
 * @param {string} name - 路由名称
 * @param {Any} [params] - 跳转参数
 * @returns {void} 无返回值
 */
export function navigateTo(name: string, params?: Any): void {
  const service: BusinessNavigationService | undefined = getNavigationService();
  service?.navigateTo(name, params);
}

/**
 * 返回上一页
 * @returns {void} 无返回值
 */
export function navigateBack(): void {
  const service: BusinessNavigationService | undefined = getNavigationService();
  service?.navigateBack();
}

/**
 * 携带结果返回上一页（触发上一跳中的 onPop 回调）
 * @param {Any} [result={}] - 返回结果
 * @param {boolean} [animated=true] - 是否需要动画
 * @returns {void} 无返回值
 */
export function navigateBackWithResult(result: Any | object = {}, animated?: boolean): void {
  const service: BusinessNavigationService | undefined = getNavigationService();
  service?.navigateBackWithResult(result, animated);
}

/**
 * 返回到指定路由
 * @param {string} name - 目标路由名称
 * @param {boolean} inclusive - 是否移除目标自身（默认 false）
 * @returns {void} 无返回值
 */
export function popTo(name: string, inclusive: boolean = false): void {
  const service: BusinessNavigationService | undefined = getNavigationService();
  service?.popTo(name, inclusive);
}

/**
 * 跳转并监听返回结果（使用 ArkUI promise 版本 pushDestinationByName）
 * @param {string} name - 路由名称
 * @param {Any} [params] - 跳转参数
 * @param {(info: PopInfo) => void} [onPop] - 返回结果回调（在目标页调用 pop(result) 时触发）
 * @returns {Promise<void>} 跳转完成 Promise
 */
export function navigateToWithResult(name: string, params?: Any, onPop?: (info: PopInfo) => void): Promise<void> {
  const service: BusinessNavigationService | undefined = getNavigationService();
  if (!service) {
    return Promise.resolve();
  }
  return service?.navigateToWithResult(name, params, onPop);
}

/**
 * 跳转并以 Promise 形式获取返回结果（上层可 await）
 * @template T
 * @param {string} name - 路由名称
 * @param {Any} [params] - 跳转参数
 * @returns {Promise<T | undefined>} 返回结果（未回传时为 undefined）
 */
export function navigateToForResult<T>(name: string, params?: Any): Promise<T | undefined> {
  const service: BusinessNavigationService | undefined = getNavigationService();
  if (!service) {
    return Promise.resolve(undefined);
  }
  return service?.navigateToForResult(name, params);
}

/**
 * 获取指定路由的首个参数（类型安全，屏蔽 unknown）
 * @template T
 * @param {string} name - 路由名称
 * @returns {T} 参数对象；未获取到时返回 undefined
 */
export function getRouteParams<T>(name: string): T {
  const service: BusinessNavigationService | undefined = getNavigationService();
  if (!service) {
    return undefined as T;
  }
  return service?.getRouteParams(name);
}