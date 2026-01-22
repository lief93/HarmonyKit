import { Column, ColumnType, CreatedAt, PrimaryKey, Table, UpdatedAt } from "@ibestservices/ibest-orm";

/**
 * @file Demo 表实体定义，演示 IBest-ORM 的基础字段映射。
 * @author Joker.X
 */
@Table({ name: "demo_items" })
export class DemoEntity {
  /**
   * 主键 ID
   */
  @PrimaryKey({ autoIncrement: true })
  id?: number;
  /**
   * 标题
   */
  @Column({ type: ColumnType.TEXT })
  title?: string;
  /**
   * 描述
   */
  @Column({ type: ColumnType.TEXT })
  description?: string;
  /**
   * 创建时间
   */
  @CreatedAt()
  createdAt?: string;
  /**
   * 更新时间
   */
  @UpdatedAt()
  updatedAt?: string;
}
