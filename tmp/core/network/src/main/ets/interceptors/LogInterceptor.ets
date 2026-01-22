import { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from "@ohos/axios";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Unknown } from "model";

/**
 * @file 网络日志拦截器：输出请求与响应日志
 * @author Joker.X
 */

const DOMAIN: number = 0;
const TAG: string = "NetLog";
const MAX_LOG_LENGTH: number = 800;

/**
 * 绑定网络日志拦截器
 * @param {AxiosInstance} axiosInstance - Axios 实例
 * @returns {void} 无返回值
 */
export function setupLogInterceptor(axiosInstance: AxiosInstance): void {
  axiosInstance.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
      logRequest(config);
      return config;
    },
    (error: AxiosError) => {
      logRequestError(error);
      return Promise.reject(error);
    }
  );

  axiosInstance.interceptors.response.use(
    (response: AxiosResponse) => {
      logResponse(response);
      return response;
    },
    (error: AxiosError) => {
      logResponseError(error);
      return Promise.reject(error);
    }
  );
}

/**
 * 打印请求日志
 * @param {InternalAxiosRequestConfig} config - 请求配置
 * @returns {void} 无返回值
 */
function logRequest(config: InternalAxiosRequestConfig): void {
  const method: string = normalizeMethod(config.method);
  const url: string = buildRequestUrl(config);
  const params: string = safeStringify(config.params as Unknown, true);
  const data: string = safeStringify(config.data as Unknown, true);
  logInfoLines([
    "[Network] Request",
    `method=${method}`,
    `url=${url}`,
    `params=${params}`,
    `data=${data}`
  ]);
}

/**
 * 打印请求错误日志
 * @param {AxiosError} error - 请求错误
 * @returns {void} 无返回值
 */
function logRequestError(error: AxiosError): void {
  const config: InternalAxiosRequestConfig | undefined = error.config as InternalAxiosRequestConfig | undefined;
  const method: string = config ? normalizeMethod(config.method) : "UNKNOWN";
  const url: string = config ? buildRequestUrl(config) : "unknown";
  const message: string = error.message || "unknown";
  logErrorLines([
    "[Network] Request Error",
    `method=${method}`,
    `url=${url}`,
    `message=${message}`
  ]);
}

/**
 * 打印响应日志
 * @param {AxiosResponse} response - 响应结果
 * @returns {void} 无返回值
 */
function logResponse(response: AxiosResponse): void {
  const config: InternalAxiosRequestConfig = response.config as InternalAxiosRequestConfig;
  const url: string = buildRequestUrl(config);
  const status: string = String(response.status);
  const data: string = safeStringify(response.data as Unknown, true);
  logInfoLines([
    "[Network] Response",
    `status=${status}`,
    `url=${url}`,
    `data=${data}`
  ]);
}

/**
 * 打印响应错误日志
 * @param {AxiosError} error - 响应错误
 * @returns {void} 无返回值
 */
function logResponseError(error: AxiosError): void {
  const config: InternalAxiosRequestConfig | undefined = error.config as InternalAxiosRequestConfig | undefined;
  const response: AxiosResponse | undefined = error.response as AxiosResponse | undefined;
  const url: string = response ? buildRequestUrl(response.config as InternalAxiosRequestConfig)
    : (config ? buildRequestUrl(config) : "unknown");
  const status: string = response?.status !== undefined ? String(response.status) : "UNKNOWN";
  const data: string = response ? safeStringify(response.data as Unknown, true) : "";
  const message: string = error.message || "unknown";
  logErrorLines([
    "[Network] Response Error",
    `status=${status}`,
    `url=${url}`,
    `message=${message}`,
    `data=${data}`
  ]);
}

/**
 * 规范化请求方法
 * @param {string | undefined} method - 请求方法
 * @returns {string} 规范化后的请求方法
 */
function normalizeMethod(method?: string): string {
  return method ? method.toUpperCase() : "UNKNOWN";
}

/**
 * 拼接请求地址
 * @param {InternalAxiosRequestConfig} config - 请求配置
 * @returns {string} 拼接后的请求地址
 */
function buildRequestUrl(config: InternalAxiosRequestConfig): string {
  const baseUrl: string = config.baseURL ?? "";
  const url: string = config.url ?? "";
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  // 处理 baseURL 与 url 的拼接，避免双斜杠
  if (baseUrl.endsWith("/") && url.startsWith("/")) {
    return `${baseUrl}${url.slice(1)}`;
  }
  if (!baseUrl.endsWith("/") && url && !url.startsWith("/")) {
    return `${baseUrl}/${url}`;
  }
  return `${baseUrl}${url}`;
}

/**
 * 安全序列化
 * @param {Unknown} value - 待序列化的值
 * @returns {string} 序列化后的字符串
 */
function safeStringify(value: Unknown, pretty: boolean = false): string {
  if (value === undefined) {
    return "undefined";
  }
  if (typeof value === "string") {
    return value;
  }
  try {
    const result: string | undefined = JSON.stringify(value, null, pretty ? 2 : undefined);
    return result !== undefined ? result : String(value);
  } catch (err) {
    return "[Unserializable]";
  }
}

/**
 * 输出 info 日志（支持多行与分段）
 * @param {string[]} lines - 日志行
 * @returns {void} 无返回值
 */
function logInfoLines(lines: string[]): void {
  logLines("info", lines);
}

/**
 * 输出 error 日志（支持多行与分段）
 * @param {string[]} lines - 日志行
 * @returns {void} 无返回值
 */
function logErrorLines(lines: string[]): void {
  logLines("error", lines);
}

/**
 * 按行与长度分割日志，避免单条日志过长被截断
 * @param {"info" | "error"} level - 日志级别
 * @param {string[]} lines - 日志行
 * @returns {void} 无返回值
 */
function logLines(level: "info" | "error", lines: string[]): void {
  const logger: (domain: number, tag: string, format: string, content: string) => void =
    level === "error" ? hilog.error : hilog.info;
  lines.forEach((line: string) => {
    splitLines(line).forEach((segment: string) => {
      splitChunks(segment, MAX_LOG_LENGTH).forEach((chunk: string) => {
        logger(DOMAIN, TAG, "%{public}s", chunk);
      });
    });
  });
}

/**
 * 按换行符拆分字符串
 * @param {string} value - 原始字符串
 * @returns {string[]} 拆分后的行
 */
function splitLines(value: string): string[] {
  if (!value) {
    return [""];
  }
  return value.split("\n");
}

/**
 * 按最大长度拆分字符串
 * @param {string} value - 原始字符串
 * @param {number} maxLength - 单段最大长度
 * @returns {string[]} 拆分后的片段
 */
function splitChunks(value: string, maxLength: number): string[] {
  if (value.length <= maxLength) {
    return [value];
  }
  const result: string[] = [];
  for (let start: number = 0; start < value.length; start += maxLength) {
    result.push(value.slice(start, start + maxLength));
  }
  return result;
}
