import { BaseViewModel } from "base";
import { DemoNavigator } from "navigation";
import { CoreCardItem } from "../model/CoreCardItem";

/**
 * @file 核心页面 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class CoreViewModel extends BaseViewModel {
  /**
   * 核心模块卡片数据
   */
  @Trace
  readonly cards: CoreCardItem[] = [
    {
      title: $r("app.string.main_core_network_demo_title"),
      description: $r("app.string.main_core_network_demo_desc"),
      onClick: () => DemoNavigator.toNetworkDemo()
    },
    {
      title: $r("app.string.main_core_network_list_demo_title"),
      description: $r("app.string.main_core_network_list_demo_desc"),
      onClick: () => DemoNavigator.toNetworkListDemo()
    },
    {
      title: $r("app.string.main_core_database_title"),
      description: $r("app.string.main_core_database_desc"),
      onClick: () => DemoNavigator.toDatabase()
    },
    {
      title: $r("app.string.main_core_local_storage_title"),
      description: $r("app.string.main_core_local_storage_desc"),
      onClick: () => DemoNavigator.toLocalStorage()
    },
    {
      title: $r("app.string.main_core_state_management_title"),
      description: $r("app.string.main_core_state_management_desc"),
      onClick: () => DemoNavigator.toStateManagement()
    },
    {
      title: $r("app.string.main_core_network_request_title"),
      description: $r("app.string.main_core_network_request_desc"),
      onClick: () => DemoNavigator.toNetworkRequest()
    }
  ];
}
