import { AxiosInstance, AxiosResponse, InternalAxiosRequestConfig, AxiosError, AxiosHeaders } from "@ohos/axios";
import { TokenStoreDataSource, TokenStoreDataSourceImpl } from "datastore";
import { setupLogInterceptor } from "./LogInterceptor";

/**
 * @file 全局网络拦截器注册
 * @author Joker.X
 */

/**
 * 配置全局网络拦截器
 * @param {AxiosInstance} axiosInstance - Axios 实例
 * @returns {void} 无返回值
 */
export function setupInterceptors(axiosInstance: AxiosInstance): void {
  setupLogInterceptor(axiosInstance);

  // 请求拦截器
  axiosInstance.interceptors.request.use(
    async (config: InternalAxiosRequestConfig): Promise<InternalAxiosRequestConfig> => {
      const tokenStore: TokenStoreDataSource = new TokenStoreDataSourceImpl();
      const token: string = await tokenStore.getToken();
      if (token) {
        const headers: AxiosHeaders = AxiosHeaders.from(config.headers);
        headers.set("Authorization", token);
        config.headers = headers;
      }
      return config;
    },
    (error: AxiosError) => {
      return Promise.reject(error);
    }
  );

  // 响应拦截器
  axiosInstance.interceptors.response.use(
    (response: AxiosResponse) => {
      return response;
    },
    (error: AxiosError) => {
      return Promise.reject(error);
    }
  );
}
