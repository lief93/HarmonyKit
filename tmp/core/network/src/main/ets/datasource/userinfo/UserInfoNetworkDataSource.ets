import { NetworkResponse, User } from "model";

/**
 * @file 用户信息相关数据源接口
 * @author Joker.X
 */
export interface UserInfoNetworkDataSource {
  /**
   * 获取用户个人信息
   * @returns 用户信息响应
   */
  getPersonInfo(): Promise<NetworkResponse<User>>;
}
