import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 255 })
  message!: string;

  @Column({ type: 'varchar', length: 20, default: 'queued' })
  status!: 'queued' | 'completed';

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
