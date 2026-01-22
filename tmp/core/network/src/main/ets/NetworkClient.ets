import axios, { AxiosInstance, AxiosResponse, AxiosError } from '@ohos/axios';

import { setupInterceptors } from './interceptors/AppInterceptors';

/**
 * 网络客户端
 * 管理 Axios 实例和拦截器配置。
 * @author Joker.X
 */
export class NetworkClient {
  // 单例实例
  private static instance: NetworkClient;
  // Axios 实例
  private axiosInstance: AxiosInstance;
  // 基础 URL
  private readonly BASE_URL = 'https://mall.dusksnow.top/app/';

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: this.BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    // 初始化拦截器
    setupInterceptors(this.axiosInstance);
  }

  /**
   * 获取 NetworkClient 单例
   */
  public static getInstance(): NetworkClient {
    if (!NetworkClient.instance) {
      NetworkClient.instance = new NetworkClient();
    }
    return NetworkClient.instance;
  }

  /**
   * 获取 Axios 实例
   */
  public getAxios(): AxiosInstance {
    return this.axiosInstance;
  }

  /**
   * 静态访问属性，方便直接通过 NetworkClient.http 调用
   */
  public static get http(): AxiosInstance {
    return NetworkClient.getInstance().getAxios();
  }
}

export { AxiosResponse, AxiosError };
