import common from "@ohos.app.ability.common";
import preferences from "@ohos.data.preferences";
import { ContextUtil, PreferencesUtil } from "util";
import { TokenStoreDataSource } from "./TokenStoreDataSource";

/**
 * @file Token 本地存储数据源实现，基于 Preferences 封装
 * @author Joker.X
 */
export class TokenStoreDataSourceImpl implements TokenStoreDataSource {
  /**
   * Preferences 工具实例
   */
  private prefs: PreferencesUtil;
  /**
   * Preferences 文件名，用于存储 Token
   */
  private static readonly PREFS_NAME: string = "token_store";
  /**
   * Token 键名
   */
  private static readonly KEY_TOKEN: string = "token";

  /**
   * 构造函数
   * @param {common.Context} [context] UIAbility 上下文
   */
  constructor(context?: common.Context) {
    const resolvedContext: common.Context = context ?? ContextUtil.getUIAbilityCtx();
    this.prefs = new PreferencesUtil(resolvedContext, TokenStoreDataSourceImpl.PREFS_NAME);
  }

  /**
   * 保存 Token
   * @param {string} token Token
   * @returns {Promise<void>} Promise<void>
   */
  async setToken(token: string): Promise<void> {
    await this.prefs.set(TokenStoreDataSourceImpl.KEY_TOKEN, token);
  }

  /**
   * 读取 Token（默认返回空字符串）
   * @returns {Promise<string>} Token
   */
  async getToken(): Promise<string> {
    const value: preferences.ValueType = await this.prefs.get(TokenStoreDataSourceImpl.KEY_TOKEN, "");
    return typeof value === "string" ? value : "";
  }

  /**
   * 清除 Token
   * @returns {Promise<void>} Promise<void>
   */
  async clearToken(): Promise<void> {
    await this.prefs.remove(TokenStoreDataSourceImpl.KEY_TOKEN);
  }
}
