/**
 * @file Token 本地存储数据源接口
 * @author Joker.X
 */
export interface TokenStoreDataSource {
  /**
   * 保存 Token
   * @param {string} token Token
   * @returns {Promise<void>} Promise<void>
   */
  setToken(token: string): Promise<void>;

  /**
   * 读取 Token
   * @returns {Promise<string>} Token，默认空字符串
   */
  getToken(): Promise<string>;

  /**
   * 清除 Token
   * @returns {Promise<void>} Promise<void>
   */
  clearToken(): Promise<void>;
}
