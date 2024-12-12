import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

const API_URL = "https://chat-2137.bstrama.com";

void main() {
  runApp(const Chat2137App());
}

class Chat2137App extends StatelessWidget {
  const Chat2137App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat 2137',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JoinRoomScreen(),
    );
  }
}

class JoinRoomScreen extends StatefulWidget {
  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();

  void _joinChat() {
    final roomCode = _roomController.text.trim();
    final nick = _nickController.text.trim();

    if (roomCode.isNotEmpty && nick.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomCode: roomCode, nick: nick),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Chat Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _roomController,
              decoration: InputDecoration(labelText: 'Room Code'),
            ),
            TextField(
              controller: _nickController,
              decoration: InputDecoration(labelText: 'Nick'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinChat,
              child: Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String roomCode;
  final String nick;

  ChatScreen({required this.roomCode, required this.nick});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _setupSocketConnection();
  }

  void _setupSocketConnection() {
    _socket = IO.io(API_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    print("connecting...");
    _socket.connect();
    print("connected");

    _socket.on('connect', (_) {
      _socket.emit('joinRoom', widget.roomCode);
    });

    _socket.on('receiveMessage', (data) {
      setState(() {
        _messages.add(data);
      });
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final body = {
        'username': widget.nick,
        'roomCode': widget.roomCode,
        'content': message,
      };

      print("sendMessage");
      _socket.emit('sendMessage', body);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomCode}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['username']),
                  subtitle: Text(message['content']),
                  trailing: Text(message['createdAt']),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
