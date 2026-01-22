import { BaseViewModel } from "base";
import { AuthRepository } from "data";
import { Auth, PasswordLoginRequest } from "model";
import { navigateBack } from "navigation";
import { RequestHelper } from "result";
import { getUserState, UserState } from "state";
import { ToastUtils } from "util";

/**
 * @file 登录页 ViewModel
 * @author Joker.X
 */
@ObservedV2
export default class LoginViewModel extends BaseViewModel {
  /**
   * 全局用户状态
   */
  private readonly userState: UserState = getUserState();
  /**
   * 认证仓库
   */
  private readonly authRepository: AuthRepository = new AuthRepository();
  /**
   * 登录按钮加载状态
   */
  @Trace
  isLoginLoading: boolean = false;

  /**
   * 执行登录操作
   * @returns {void} 无返回值
   */
  login(): void {
    const params: PasswordLoginRequest = new PasswordLoginRequest(
      "16666666666",
      "123456"
    );
    RequestHelper.repository(this.authRepository.loginByPassword(params))
      .start((): void => {
        this.isLoginLoading = true;
      })
      .execute()
      .then((authData: Auth): void => {
        this.onLoginSuccess(authData);
      })
      .finally((): void => {
        this.isLoginLoading = false;
      });
  }

  /**
   * 登录成功处理
   * @param {Auth} authData - 认证数据
   */
  private async onLoginSuccess(authData: Auth) {
    this.userState.updateAuth(authData);
    this.userState.refreshUserInfo();
    ToastUtils.showSuccess($r("app.string.login_success"));
    navigateBack();
  }
}
