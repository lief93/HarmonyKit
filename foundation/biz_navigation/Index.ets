/**
 * @file biz-navigation 模块统一导出
 * @author Joker.X junbin.yang
 */

export { AuthNavigator } from "./src/main/ets/auth/AuthNavigator";

export { MainNavigator } from "./src/main/ets/main/MainNavigator";

export { UserNavigator } from "./src/main/ets/user/UserNavigator";

export { DemoNavigator } from "./src/main/ets/demo/DemoNavigator";

export { UserAddressDetailParam, UserAddressListParam } from "./src/main/ets/user/UserParam";

export { DemoResult } from "./src/main/ets/demo/DemoResult";

export {
  NAV_PATH_STACK_KEY,
  getRouteParams,
  getNavPathStack,
  navigateBack,
  navigateBackWithResult,
  navigateTo,
  navigateToForResult,
  navigateToWithResult,
  popTo,
  setNavPathStack
} from "./src/main/ets/BusinessNavigationService";