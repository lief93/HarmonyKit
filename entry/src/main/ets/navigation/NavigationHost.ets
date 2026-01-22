import { MainPage } from '@feature/main';
import { RouteBuild } from '@core/navigation';
import { NAV_PATH_STACK_KEY, setNavPathStack } from '@foundation/biz-navigation';

/**
 * @file 挂载全局导航栈
 * @author Joker.X
 */
@ComponentV2
export struct NavigationHost {
  /**
   * 导航栈
   */
  @Provider(NAV_PATH_STACK_KEY)
  navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    setNavPathStack(this.navPathStack);
  }

  /**
   * 导航目标构建器
   * @param name 路由名称
   * @returns 路由构建器
   */
  @Builder
  PagesMap(name: string) {
    if (RouteBuild.getBuilder(name) !== undefined) {
      (RouteBuild.getBuilder(name) as WrappedBuilder<[]>).builder();
    }
  }

  /**
   * 导航目标构建器
   * @returns 路由构建器
   */
  build() {
    Navigation(this.navPathStack) {
      MainPage()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
  }
}
