import { PersistenceV2, Type } from "@kit.ArkUI";
import { contextConstant } from "@kit.AbilityKit";
import { TokenStoreRepository, UserInfoRepository } from "data";
import { Auth, User } from "model";
import { RequestHelper } from "result";

/**
 * @file 全局用户状态（持久化），提供跨页面共享的响应式状态
 * @author Joker.X
 */

/**
 * AppStorageV2 键名
 */
export const USER_STATE_KEY: string = "user_state";

/**
 * 全局用户状态
 */
@ObservedV2
export class UserState {
  /**
   * 认证信息
   */
  @Type(Auth)
  @Trace
  private auth: Auth = new Auth();
  /**
   * 用户信息
   */
  @Type(User)
  @Trace
  userInfo: User = new User();

  /**
   * 更新用户登录状态（认证 + 用户信息）
   * @param {Auth} auth - 认证信息
   * @param {User} user - 用户信息
   * @returns {void} 无返回值
   * @example
  * getUserState().updateUserState(new Auth(), new User());
   */
  updateUserState(auth: Auth, user: User): void {
    this.auth = Auth.fromResponse(auth);
    this.userInfo = User.fromResponse(user);
    new TokenStoreRepository().saveToken(this.auth.token);
    this.persist();
  }

  /**
   * 更新用户信息
   * @param {User} user - 新的用户信息
   * @returns {void} 无返回值
   * @example
  * getUserState().updateUserInfo(new User({ nickName: "ArkUI" }));
   */
  updateUserInfo(user: User): void {
    this.userInfo = User.fromResponse(user);
    this.persist();
  }

  /**
   * 更新认证信息（例如刷新 token）
   * @param {Auth} auth - 新的认证信息
   * @returns {void} 无返回值
   * @example
  * getUserState().updateAuth(new Auth({ token: "abc" }));
   */
  updateAuth(auth: Auth): void {
    this.auth = Auth.fromResponse(auth);
    new TokenStoreRepository().saveToken(this.auth.token);
    this.persist();
  }

  /**
   * 用户登出，清空状态
   * @returns {void} 无返回值
   * @example
  * getUserState().logout();
   */
  logout(): void {
    this.auth = new Auth();
    this.userInfo = new User();
    new TokenStoreRepository().clearToken();
    PersistenceV2.remove(USER_STATE_KEY);
  }

  /**
   * 是否需要刷新 token（过期前15分钟）
   * @returns {boolean} 是否需要刷新
   * @example
  * const needRefresh = getUserState().shouldRefreshToken();
   */
  shouldRefreshToken(): boolean {
    if (!this.auth) {
      return false;
    }
    return this.auth.shouldRefresh();
  }

  /**
   * 从网络刷新用户信息
   * @returns {void} 无返回值
   * @example
  * getUserState().refreshUserInfo();
   */
  refreshUserInfo(): void {
    if (!this.isLoggedIn()) {
      return;
    }
    RequestHelper.repository(new UserInfoRepository().getPersonInfo())
      .execute()
      .then((userInfo: User): void => {
        this.updateUserInfo(userInfo);
      });
  }

  /**
   * 获取当前 token
   * @returns {string} token 字符串，未登录返回空串
   */
  getToken(): string | null {
    return this.auth?.token ?? null;
  }

  /**
   * 获取当前用户信息
   * @returns {User} 用户信息，未登录返回空对象
   */
  getUserInfo(): User {
    return this.userInfo;
  }

  /**
   * 获取当前用户 ID
   * @returns {number | null} 用户 ID，未登录返回 null
   */
  getUserId(): number | null {
    return this.userInfo?.id ?? null;
  }

  /**
   * 当前是否已登录（依据 auth 与 userInfo 是否存在）
   * @returns {boolean} 登录状态
   */
  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  /**
   * 是否拥有未过期的访问令牌
   * @returns {boolean} 是否可用
   */
  hasValidToken(): boolean {
    return !!this.auth?.token && !this.auth.isExpired();
  }

  /**
   * 获取刷新 token
   * @returns {string | null} 刷新 token
   */
  getRefreshToken(): string | null {
    return this.auth?.refreshToken ?? null;
  }

  /**
   * 持久化当前用户状态
   * @returns {void} 无返回值
   */
  private persist(): void {
    PersistenceV2.save(USER_STATE_KEY);
  }
}

/**
 * 获取或创建全局用户状态（持久化）
 * @returns {UserState} 全局用户状态
 * @example
* const state = getUserState();
 */
export function getUserState(): UserState {
  return PersistenceV2.globalConnect<UserState>({
    type: UserState,
    key: USER_STATE_KEY,
    defaultCreator: () => new UserState(),
    areaMode: contextConstant.AreaMode.EL3
  })!;
}

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});
