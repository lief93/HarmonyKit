import { RouteBuild, RouteGraph } from "navigation";
import { DemoRoutes } from "navigation/src/main/ets/demo/DemoRoutes";
import { NetworkDemoNav } from "./NetworkDemoNav";
import { NetworkListDemoNav } from "./NetworkListDemoNav";
import { DatabaseNav } from "./DatabaseNav";
import { LocalStorageNav } from "./LocalStorageNav";
import { StateManagementNav } from "./StateManagementNav";
import { NetworkRequestNav } from "./NetworkRequestNav";
import { NavigationWithArgsNav } from "./NavigationWithArgsNav";
import { NavigationResultNav } from "./NavigationResultNav";
import { SafeAreaDemoNav } from "./SafeAreaDemoNav";
import { ScreenAdaptDemoNav } from "./ScreenAdaptDemoNav";

/**
 * @file Demo 模块导航图
 * @author Joker.X
 */
export class DemoGraph implements RouteGraph {
  /**
   * 注册 Demo 模块导航路由
   * @returns {void} 无返回值
   */
  register(): void {
    RouteBuild.register(DemoRoutes.NetworkDemo, wrapBuilder(NetworkDemoNav));
    RouteBuild.register(DemoRoutes.NetworkListDemo, wrapBuilder(NetworkListDemoNav));
    RouteBuild.register(DemoRoutes.Database, wrapBuilder(DatabaseNav));
    RouteBuild.register(DemoRoutes.LocalStorage, wrapBuilder(LocalStorageNav));
    RouteBuild.register(DemoRoutes.StateManagement, wrapBuilder(StateManagementNav));
    RouteBuild.register(DemoRoutes.NetworkRequest, wrapBuilder(NetworkRequestNav));
    RouteBuild.register(DemoRoutes.NavigationWithArgs, wrapBuilder(NavigationWithArgsNav));
    RouteBuild.register(DemoRoutes.NavigationResult, wrapBuilder(NavigationResultNav));
    RouteBuild.register(DemoRoutes.SafeAreaDemo, wrapBuilder(SafeAreaDemoNav));
    RouteBuild.register(DemoRoutes.ScreenAdaptDemo, wrapBuilder(ScreenAdaptDemoNav));
  }
}
