import { Goods, NetworkResponse } from 'model';
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
