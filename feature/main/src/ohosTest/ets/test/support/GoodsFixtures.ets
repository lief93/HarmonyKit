import { Goods, NetworkPageData, NetworkPageMeta, NetworkResponse } from 'model';
import { MOCK_GOODS_SUB_TITLE, MOCK_GOODS_TITLE } from './TestValues';

export function createMockGoodsResponse(): NetworkResponse<Goods> {
  const goods: Goods = new Goods();
  goods.id = 1;
  goods.title = MOCK_GOODS_TITLE;
  goods.subTitle = MOCK_GOODS_SUB_TITLE;
  const response: NetworkResponse<Goods> = new NetworkResponse<Goods>();
  response.data = goods;
  return response;
}

export function createBusinessErrorResponse(): NetworkResponse<Goods> {
  const response: NetworkResponse<Goods> = new NetworkResponse<Goods>();
  response.code = 500;
  response.message = 'Mock business failure';
  return response;
}

export function createEmptyGoodsPageResponse(): NetworkResponse<NetworkPageData<Goods>> {
  const pageData: NetworkPageData<Goods> = new NetworkPageData<Goods>();
  pageData.list = [];
  const pagination: NetworkPageMeta = new NetworkPageMeta();
  pagination.page = 1;
  pagination.size = 10;
  pagination.total = 0;
  pageData.pagination = pagination;
  const response: NetworkResponse<NetworkPageData<Goods>> = new NetworkResponse<NetworkPageData<Goods>>();
  response.data = pageData;
  return response;
}

export function createMockGoodsPageResponse(): NetworkResponse<NetworkPageData<Goods>> {
  const goods: Goods = new Goods();
  goods.id = 2;
  goods.title = MOCK_GOODS_TITLE;
  goods.subTitle = MOCK_GOODS_SUB_TITLE;
  const pageData: NetworkPageData<Goods> = new NetworkPageData<Goods>();
  pageData.list = [goods];
  const pagination: NetworkPageMeta = new NetworkPageMeta();
  pagination.page = 1;
  pagination.size = 10;
  pagination.total = 1;
  pageData.pagination = pagination;
  const response: NetworkResponse<NetworkPageData<Goods>> = new NetworkResponse<NetworkPageData<Goods>>();
  response.data = pageData;
  return response;
}
