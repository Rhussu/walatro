import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:walatro/models/player.dart'; // Asegúrate de importar el archivo anterior

class RoomService {
  late IO.Socket socket;
  
  String? currentRoom;
  String? myName;

  Function(String status)? onConnectionStatus;
  Function(String roomCode, List<Player> users)? onRoomJoined; // ¡Ahora usa Player!
  Function(Player user)? onUserJoined;
  Function(String userName)? onUserLeft;
  Function(String senderName, String message)? onChatMessage;
  Function(String userName, bool isReady)? onReadyChanged;
  Function()? onGameStarted;
  Function(String errorMessage)? onError;
  Function(Map<String, dynamic> data)? onGameAction;

  void connect(String serverUrl) {
    socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _setupListeners();
    socket.connect();
    onConnectionStatus?.call('connecting');
  }

  void _setupListeners() {
    socket.onConnect((_) => onConnectionStatus?.call('connected'));
    socket.onDisconnect((_) => onConnectionStatus?.call('disconnected'));
    socket.onConnectError((_) => onConnectionStatus?.call('disconnected'));

    socket.on('room_joined', (data) {
      currentRoom = data['roomCode'];
      List<Player> users = (data['users'] as List).map((u) => Player.fromJson(u)).toList();
      onRoomJoined?.call(currentRoom!, users);
    });

    socket.on('user_joined', (data) => onUserJoined?.call(Player.fromJson(data)));
    socket.on('user_left', (data) => onUserLeft?.call(data['userName']));
    socket.on('chat_message', (data) => onChatMessage?.call(data['senderName'], data['message']));
    socket.on('error', (data) => onError?.call(data.toString()));
    socket.on('game_action', (data) => onGameAction?.call(Map<String, dynamic>.from(data)));

    // Nuevos eventos
    socket.on('ready_changed', (data) => onReadyChanged?.call(data['userName'], data['isReady']));
    socket.on('game_started', (_) => onGameStarted?.call());
  }

  void createRoom(String userName) {
    myName = userName;
    socket.emit('create_room', {'userName': userName});
  }

  void joinRoom(String roomCode, String userName) {
    myName = userName;
    socket.emit('join_room', {'roomCode': roomCode, 'userName': userName});
  }

  void sendChat(String text) {
    if (currentRoom != null && myName != null) {
      socket.emit('send_chat', {'roomCode': currentRoom, 'senderName': myName, 'message': text});
    }
  }

  // Nuevas acciones para el Ready y Empezar
  void setReady(bool isReady) {
    if (currentRoom != null && myName != null) {
      socket.emit('set_ready', {'roomCode': currentRoom, 'userName': myName, 'isReady': isReady});
    }
  }

  void startGame() {
    if (currentRoom != null) {
      socket.emit('start_game', currentRoom);
    }
  }

  void sendGameAction(String actionType, dynamic payload) {
    if (currentRoom != null && myName != null) {
      socket.emit('game_action', {'roomCode': currentRoom, 'sender': myName, 'action': actionType, 'payload': payload});
    }
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}