/**
 * @file 网络通用响应模型
 * @author Joker.X
 */
export class NetworkResponse<T> {
  /**
   * 真实数据
   */
  data: T | null;
  /**
   * 状态码，等于1000表示成功
   */
  code: number;
  /**
   * 错误提示信息
   */
  message: string | null;

  /**
   * 构造函数，对接口返回做空值兜底
   * @param {Partial<NetworkResponse<T>>} payload - 接口原始数据
   */
  constructor(payload?: Partial<NetworkResponse<T>>) {
    this.data = payload?.data ?? null;
    this.code = payload?.code !== undefined ? Number(payload.code) : 1000;
    this.message = payload?.message ?? null;
  }

  /**
   * 是否成功
   * @returns {boolean} 是否请求成功
   */
  get isSucceeded(): boolean {
    // 状态码为1000表示成功
    return this.code === 1000;
  }
}
