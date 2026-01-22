import { UserInfoNetworkDataSource, UserInfoNetworkDataSourceImpl } from "@foundation/network";
import { User } from "@foundation/biz-model";
import { NetworkResponse } from "@core/model";

/**
 * @file 用户信息仓库，封装用户信息相关请求
 * @author Joker.X
 */
export class UserInfoRepository {
  /**
   * 用户信息网络数据源
   */
  private networkDataSource: UserInfoNetworkDataSource;

  /**
   * 构造函数
   * @param {UserInfoNetworkDataSource} networkDataSource - 可选的用户信息数据源实例
   */
  constructor(networkDataSource?: UserInfoNetworkDataSource) {
    this.networkDataSource = networkDataSource ?? new UserInfoNetworkDataSourceImpl();
  }

  /**
   * 获取用户个人信息
   * @returns {Promise<NetworkResponse<User>>} 用户信息响应
   */
  async getPersonInfo(): Promise<NetworkResponse<User>> {
    return this.networkDataSource.getPersonInfo();
  }
}
