import { AxiosResponse } from "@ohos/axios";
import { NetworkClient } from "../../NetworkClient";
import { NetworkResponse, User } from "model";
import { UserInfoNetworkDataSource } from "./UserInfoNetworkDataSource";

/**
 * @file 用户信息相关数据源实现类
 * @author Joker.X
 */
export class UserInfoNetworkDataSourceImpl implements UserInfoNetworkDataSource {
  /**
   * 获取个人信息
   * @returns {Promise<NetworkResponse<User>>} 个人信息
   */
  async getPersonInfo(): Promise<NetworkResponse<User>> {
    const resp: AxiosResponse<NetworkResponse<User>> =
      await NetworkClient.http.get("user/info/person");
    return resp.data;
  }
}
