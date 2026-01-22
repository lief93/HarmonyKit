import { AuthRoutes } from "./auth/AuthRoutes";
import { UserRoutes } from "./user/UserRoutes";

/**
 * @file 路由拦截配置（登录校验）
 * @author Joker.X
 */

/**
 * 受保护路由名称列表
 */
const PROTECTED_ROUTES = [
  // 用户模块
  UserRoutes.Profile,
] as const;

/**
 * 受保护路由名称的联合类型
 */
export type ProtectedRouteName = typeof PROTECTED_ROUTES[number];

/**
 * 需要登录的路由集合
 */
const loginRequiredRouteNames: Set<ProtectedRouteName> = new Set<ProtectedRouteName>(PROTECTED_ROUTES);

/**
 * 判断路由是否需要登录
 * @param {string} routeName - 路由名称
 * @returns {boolean} true表示需要登录
 */
export function requiresLogin(routeName: string): boolean {
  return loginRequiredRouteNames.has(routeName as ProtectedRouteName);
}

/**
 * 获取登录页路由名称
 * @returns {ProtectedRouteName} 登录页路由
 */
export function getLoginRoute(): ProtectedRouteName {
  return AuthRoutes.Login as ProtectedRouteName;
}

/**
 * 获取所有需要登录的路由名称
 * @returns {ProtectedRouteName[]} 需要登录的路由列表
 */
export function getLoginRequiredRoutes(): ProtectedRouteName[] {
  return Array.from(loginRequiredRouteNames);
}

/**
 * 新增需要登录的路由名称
 * @param {ProtectedRouteName} routeName - 路由名称
 * @returns {void} 无返回值
 */
export function addLoginRequiredRoute(routeName: ProtectedRouteName): void {
  loginRequiredRouteNames.add(routeName);
}

/**
 * 移除需要登录的路由名称
 * @param {ProtectedRouteName} routeName - 路由名称
 * @returns {void} 无返回值
 */
export function removeLoginRequiredRoute(routeName: ProtectedRouteName): void {
  loginRequiredRouteNames.delete(routeName);
}
