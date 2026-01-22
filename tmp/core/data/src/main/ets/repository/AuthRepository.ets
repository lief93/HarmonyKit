import { AuthNetworkDataSource, AuthNetworkDataSourceImpl } from "network";
import { NetworkResponse, Auth, PasswordLoginRequest } from "model";

/**
 * @file 认证相关仓库类，封装认证模块请求
 * @author Joker.X
 */
export class AuthRepository {
  /**
   * 认证网络数据源
   */
  private networkDataSource: AuthNetworkDataSource;

  /**
   * 构造函数
   * @param networkDataSource 可选的认证网络数据源实例
   */
  constructor(networkDataSource?: AuthNetworkDataSource) {
    this.networkDataSource = networkDataSource ?? new AuthNetworkDataSourceImpl();
  }

  /**
   * 刷新 Token
   * @param {Record<string, string>} params - 刷新参数
   * @returns {Promise<NetworkResponse<Auth>>} 刷新后的认证信息
   */
  async refreshToken(params: Record<string, string>): Promise<NetworkResponse<Auth>> {
    return this.networkDataSource.refreshToken(params);
  }

  /**
   * 密码登录
   * @param params 登录参数，包含用户名、密码等
   * @returns 包含认证信息的网络响应
   */
  async loginByPassword(params: PasswordLoginRequest): Promise<NetworkResponse<Auth>> {
    return this.networkDataSource.loginByPassword(params);
  }
}
