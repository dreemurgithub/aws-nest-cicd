import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TasksController } from './tasks.controller';
// import { TasksProcessor } from './tasks.processor';
import { TasksService } from './tasks.service';
import { Task } from './task.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Task]), BullModule.registerQueue({ name: 'tasks' })],
  controllers: [TasksController],
  // Re-enable TasksProcessor once the worker infrastructure is configured.
  providers: [TasksService],
})
export class TasksModule {}
