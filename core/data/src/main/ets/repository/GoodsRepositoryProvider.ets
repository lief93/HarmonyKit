import { GoodsRepository } from './GoodsRepository';

/**
 * 商品仓库提供者。默认创建真实仓库，也允许测试临时注入替代实现。
 */
export class GoodsRepositoryProvider {
  private static repository: GoodsRepository | undefined = undefined;

  /**
   * 获取商品仓库。
   * @returns 商品仓库实例
   */
  static get(): GoodsRepository {
    return GoodsRepositoryProvider.repository ?? new GoodsRepository();
  }

  /**
   * 设置临时商品仓库。
   * @param repository 商品仓库实例
   */
  static set(repository: GoodsRepository): void {
    GoodsRepositoryProvider.repository = repository;
  }

  /**
   * 恢复默认商品仓库。
   */
  static reset(): void {
    GoodsRepositoryProvider.repository = undefined;
  }
}
