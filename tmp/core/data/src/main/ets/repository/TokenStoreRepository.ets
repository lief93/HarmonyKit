import { TokenStoreDataSource, TokenStoreDataSourceImpl } from "datastore";

/**
 * @file Token 本地存储仓库，封装存取逻辑
 * @author Joker.X
 */
export class TokenStoreRepository {
  /**
   * 本地数据源实例
   */
  private dataSource: TokenStoreDataSource;

  /**
   * 构造函数
   * @param {TokenStoreDataSource} [dataSource] 可选自定义数据源
   */
  constructor(dataSource?: TokenStoreDataSource) {
    this.dataSource = dataSource ?? new TokenStoreDataSourceImpl();
  }

  /**
   * 保存 Token
   * @param {string} token Token
   * @returns {Promise<void>} Promise<void>
   */
  saveToken(token: string): Promise<void> {
    return this.dataSource.setToken(token);
  }

  /**
   * 读取 Token
   * @returns {Promise<string>} Token，默认空字符串
   */
  loadToken(): Promise<string> {
    return this.dataSource.getToken();
  }

  /**
   * 清除 Token
   * @returns {Promise<void>} Promise<void>
   */
  clearToken(): Promise<void> {
    return this.dataSource.clearToken();
  }
}
