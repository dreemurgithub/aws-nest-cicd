import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task } from './task.entity';

@Processor('tasks')
export class TasksProcessor extends WorkerHost {
  constructor(@InjectRepository(Task) private readonly tasks: Repository<Task>) {
    super();
  }

  async process(job: Job<{ taskId: string }>) {
    await this.tasks.update(job.data.taskId, { status: 'completed' });
  }
}
