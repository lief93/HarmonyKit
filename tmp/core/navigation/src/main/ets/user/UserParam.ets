/**
 * @file 用户模块导航参数定义
 * @author Joker.X
 */

/**
 * 收货地址列表参数
 */
export interface UserAddressListParam {
  /**
   * 是否为选择模式
   */
  isSelectMode?: boolean;
}

/**
 * 收货地址详情参数
 */
export interface UserAddressDetailParam {
  /**
   * 是否为编辑模式
   */
  isEditMode?: boolean;
  /**
   * 地址 ID（0表示新增）
   */
  addressId?: number;
}
