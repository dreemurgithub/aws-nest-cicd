import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateTaskDto } from './create-task.dto';
import { Task } from './task.entity';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task) private readonly tasks: Repository<Task>,
    @InjectQueue('tasks') private readonly queue: Queue,
  ) {}

  async create(input: CreateTaskDto): Promise<Task> {
    const task = await this.tasks.save(this.tasks.create(input));
    await this.queue.add('process-task', { taskId: task.id }, { removeOnComplete: 100 });
    return task;
  }
}
