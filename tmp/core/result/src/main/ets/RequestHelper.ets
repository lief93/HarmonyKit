import { NetworkResponse } from "model";
import { ToastUtils } from "util";

/**
 * @file 网络请求结果处理
 * @description 提供网络请求结果处理的助手类，自动处理异常以及简化相关代码。
 * @param T 网络请求返回数据项类型
 * @author Joker.X
 */
export class RequestHelper<T> {
  /**
   * 原始请求 Promise，类型为 NetworkResponse<T>
   */
  private source: Promise<NetworkResponse<T>>;
  /**
   * 是否为本次请求显示 loading，默认 false
   */
  private useLoading: boolean = false;
  /**
   * 是否为本次请求自动 toast 错误，默认 true
   */
  private useToast: boolean = true;
  /**
   * 请求开始前的回调（如埋点、重置状态）
   */
  private beforeStart?: () => void;

  /**
   * 构造函数
   * @param {Promise<NetworkResponse<T>>} promise - 原始请求 Promise
   */
  private constructor(promise: Promise<NetworkResponse<T>>) {
    this.source = promise;
  }

  /**
   * 配置请求源仓库（Repository/API 返回的 Promise）
   * @param {Promise<NetworkResponse<T>>} promise - 原始请求 Promise
   * @returns {RequestHelper<T>} 链式助手实例
   */
  static repository<T>(promise: Promise<NetworkResponse<T>>): RequestHelper<T> {
    return new RequestHelper<T>(promise);
  }

  /**
   * 设置请求开始前执行的回调
   * @param {() => void} handler - 前置回调
   * @returns {RequestHelper<T>} 当前实例
   */
  start(handler: () => void): RequestHelper<T> {
    this.beforeStart = handler;
    return this;
  }

  /**
   * 返回完整响应（code / data / message），需手动调用 then 处理
   * @returns {Promise<NetworkResponse<T>>} 完整响应 Promise
   */
  async response(): Promise<NetworkResponse<T>> {
    return this.runInternal(true);
  }

  /**
   * 配置是否展示 loading
   * @param {boolean} enable - 是否展示
   * @returns {RequestHelper<T>} 当前实例
   */
  loading(enable: boolean = false): RequestHelper<T> {
    this.useLoading = enable;
    return this;
  }

  /**
   * 配置是否自动 toast 错误
   * @param {boolean} enable - 是否展示
   * @returns {RequestHelper<T>} 当前实例
   */
  toast(enable: boolean = true): RequestHelper<T> {
    this.useToast = enable;
    return this;
  }

  /**
   * 执行请求，可 await 或 .then，默认仅返回 data
   * @returns {Promise<T>} data Promise
   */
  async execute(): Promise<T> {
    return this.runInternal(false);
  }

  /**
   * 内部执行重载：true 返回响应，false 返回 data
   */
  private async runInternal(returnFull: true): Promise<NetworkResponse<T>>;

  private async runInternal(returnFull: false): Promise<T>;

  /**
   * 核心执行逻辑
   * @param {boolean} returnFull - 是否返回完整响应
   * @returns {Promise<NetworkResponse<T> | T>} 结果
   */
  private async runInternal(returnFull: boolean): Promise<NetworkResponse<T> | T> {
    if (this.beforeStart) {
      this.beforeStart();
    }
    if (this.useLoading) {
      ToastUtils.showLoading();
    }
    try {
      const rawResp: NetworkResponse<T> = await this.source;
      const resp: NetworkResponse<T> = new NetworkResponse<T>(rawResp);
      if (resp.isSucceeded) {
        if (returnFull) {
          return resp;
        }
        return resp.data as T;
      }
      const bizMsg: string = resp.message ?? "业务失败";
      this.toastIfNeeded(bizMsg);
      throw new Error(bizMsg);
    } catch (e) {
      const err: Error = e instanceof Error ? e : new Error("网络异常");
      this.toastIfNeeded(err.message);
      throw err;
    } finally {
      if (this.useLoading) {
        ToastUtils.hide();
      }
    }
  }

  /**
   * 按需弹出错误提示
   * @param {string} message - 错误信息
   */
  private toastIfNeeded(message: string): void {
    if (this.useToast) {
      ToastUtils.showError(message);
    }
  }
}
