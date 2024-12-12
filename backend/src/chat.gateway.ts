import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaClient } from '@prisma/client';

interface MessageDto {
  username: string;
  content: string;
  roomCode: string;
}

const prisma = new PrismaClient();

@WebSocketGateway({ cors: true })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private rooms: Record<string, Set<string>> = {};

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    for (const [roomCode, users] of Object.entries(this.rooms)) {
      users.delete(client.id);
      if (users.size === 0) {
        delete this.rooms[roomCode];
      }
    }
  }

  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @MessageBody() roomCode: string,
    @ConnectedSocket() client: Socket,
  ) {
    if (!this.rooms[roomCode]) {
      this.rooms[roomCode] = new Set();
    }
    this.rooms[roomCode].add(client.id);
    client.join(roomCode);
    const messages = await prisma.message.findMany({
      where: { roomCode },
      orderBy: { createdAt: 'asc' },
    });
    client.emit('messages', messages);
    console.log(`Client ${client.id} joined room: ${roomCode}`);
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @MessageBody() message: MessageDto,
    @ConnectedSocket() client: Socket,
  ) {
    const { username, content, roomCode } = message;
    const createdAt = new Date();

    if (this.rooms[roomCode]?.has(client.id)) {
      await prisma.message.create({
        data: {
          username,
          content,
          roomCode,
          createdAt,
        },
      });

      this.server
        .to(roomCode)
        .emit('receiveMessage', { username, content, createdAt });
      console.log(`Message sent to room ${roomCode}:`, {
        username,
        content,
        createdAt,
      });
    } else {
      client.emit('error', 'You are not part of this room.');
    }
  }
}
