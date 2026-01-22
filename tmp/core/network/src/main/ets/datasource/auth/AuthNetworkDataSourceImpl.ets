import { AxiosResponse } from "@ohos/axios";
import { NetworkClient } from "../../NetworkClient";
import { Auth, NetworkResponse, PasswordLoginRequest } from "model";
import { AuthNetworkDataSource } from "./AuthNetworkDataSource";

/**
 * @file 认证相关网络数据源实现类
 * @author Joker.X
 */
export class AuthNetworkDataSourceImpl implements AuthNetworkDataSource {
  /**
   * 刷新 Token
   * @param {Record<string, string>} params - 刷新参数
   * @returns {Promise<NetworkResponse<Auth>>} 刷新后的认证信息
   */
  async refreshToken(params: Record<string, string>): Promise<NetworkResponse<Auth>> {
    const response: AxiosResponse<NetworkResponse<Auth>> =
      await NetworkClient.http.post("user/login/refreshToken", params);
    return response.data;
  }

  /**
   * 密码登录实现
   * @param {Record<string, string>} params - 登录参数
   * @returns {Promise<NetworkResponse<Auth>>} 登录结果
   */
  async loginByPassword(params: PasswordLoginRequest): Promise<NetworkResponse<Auth>> {
    const response: AxiosResponse<NetworkResponse<Auth>> =
      await NetworkClient.http.post("user/login/password", params);
    return response.data;
  }
}
