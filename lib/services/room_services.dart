import 'package:socket_io_client/socket_io_client.dart' as IO;

class RoomService {
  late IO.Socket socket;
  
  String? currentRoom;
  String? myName;

  // ===== CALLBACKS PARA ACTUALIZAR TU UI =====
  Function(String roomCode, List<String> users)? onRoomJoined;
  Function(String userName)? onUserJoined;
  Function(String userName)? onUserLeft;
  Function(String senderName, String message)? onChatMessage;
  Function(String errorMessage)? onError;

  // 1. CONECTAR AL SERVIDOR
  void connect(String serverUrl) {
    socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Forzamos websocket puro
        .disableAutoConnect()
        .build());

    // Escuchar eventos desde el servidor
    _setupListeners();
    
    socket.connect();
  }

  void _setupListeners() {
    socket.onConnect((_) => print('🔌 Conectado al servidor Socket.IO'));

    // Cuando entras (o creas) la sala con éxito
    socket.on('room_joined', (data) {
      currentRoom = data['roomCode'];
      // Recibes la lista de los que ya estaban
      List<String> users = List<String>.from(data['users']); 
      onRoomJoined?.call(currentRoom!, users);
    });

    // Cuando alguien nuevo entra a tu sala
    socket.on('user_joined', (data) {
      onUserJoined?.call(data['userName']);
    });

    // Cuando alguien se va
    socket.on('user_left', (data) {
      onUserLeft?.call(data['userName']);
    });

    // Cuando recibes un mensaje del chat
    socket.on('chat_message', (data) {
      onChatMessage?.call(data['senderName'], data['message']);
    });

    // Manejo de errores (ej. "La sala no existe")
    socket.on('error', (data) {
      onError?.call(data.toString());
    });
  }

  // 2. CREAR UNA SALA NUEVA
  void createRoom(String userName) {
    myName = userName;
    // Le decimos al servidor que queremos crear una sala
    socket.emit('create_room', {'userName': userName});
  }

  // 3. UNIRSE A UNA SALA EXISTENTE
  void joinRoom(String roomCode, String userName) {
    myName = userName;
    socket.emit('join_room', {
      'roomCode': roomCode, 
      'userName': userName
    });
  }

  // 4. ENVIAR MENSAJE AL CHAT
  void sendChat(String text) {
    if (currentRoom != null && myName != null) {
      socket.emit('send_chat', {
        'roomCode': currentRoom,
        'senderName': myName,
        'message': text,
      });
    }
  }

  // LIMPIEZA
  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}