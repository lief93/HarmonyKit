import { AxiosResponse } from "@ohos/axios";
import { NetworkClient } from "../../NetworkClient";
import {
  Goods, GoodsSearchRequest, NetworkPageData, NetworkResponse
} from "model";
import { GoodsNetworkDataSource } from "./GoodsNetworkDataSource";

/**
 * @file 商品相关数据源实现类
 * @author Joker.X
 */
export class GoodsNetworkDataSourceImpl implements GoodsNetworkDataSource {
  /**
   * 分页查询商品
   * @param params 商品搜索请求参数
   * @returns 商品分页数据响应
   */
  async getGoodsPage(params: GoodsSearchRequest): Promise<NetworkResponse<NetworkPageData<Goods>>> {
    const resp: AxiosResponse<NetworkResponse<NetworkPageData<Goods>>> =
      await NetworkClient.http.post("goods/info/page", params);
    return resp.data;
  }

  /**
   * 获取商品信息
   * @param id 商品ID
   * @returns 商品信息响应
   */
  async getGoodsInfo(id: string): Promise<NetworkResponse<Goods>> {
    const resp: AxiosResponse<NetworkResponse<Goods>> =
      await NetworkClient.http.get("goods/info/info", { params: { id } });
    return resp.data;
  }
}
