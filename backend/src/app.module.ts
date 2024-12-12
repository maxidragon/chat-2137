import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { ChatGateway } from './chat.gateway';

@Module({
  controllers: [AppController],
  providers: [ChatGateway],
})
export class AppModule {}
