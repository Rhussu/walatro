import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:walatro/models/player.dart'; // Asegúrate de importar el archivo anterior

class RoomService {
  late io.Socket socket;
  
  String? currentRoom;
  String? myName;

  Function(String status)? onConnectionStatus;
  Function(String roomCode, List<Player> users)? onRoomJoined;
  Function(Player user)? onUserJoined;
  Function(String userName)? onUserLeft;
  Function(String senderName, String message)? onChatMessage;
  Function(String userName, bool isReady)? onReadyChanged;
  Function()? onGameStarted;
  Function(String errorMessage)? onError;
  Function(Map<String, dynamic> data)? onGameAction;

  // Callbacks del juego de cartas Walatro
  Map<String, dynamic>? _bufferedRoundStartedData;
  Function(Map<String, dynamic> data)? _onRoundStarted;

  Function(Map<String, dynamic> data)? get onRoundStarted => _onRoundStarted;
  set onRoundStarted(Function(Map<String, dynamic> data)? callback) {
    _onRoundStarted = callback;
    if (callback != null && _bufferedRoundStartedData != null) {
      final cached = _bufferedRoundStartedData!;
      _bufferedRoundStartedData = null;
      callback(cached);
    }
  }

  Function(String activePlayer)? onTurnChanged;
  Function(Map<String, dynamic> data)? onCardDrawn;
  Function(Map<String, dynamic> data)? onCardDiscarded;
  Function(Map<String, dynamic> data)? onCardBurned;
  Function(Map<String, dynamic> data)? onPowerActivated;
  Function(Map<String, dynamic> data)? onParityResolved;
  Function(Map<String, dynamic> data)? onPrivatePeek;
  Function(Map<String, dynamic> data)? onRoundEnded;
  Function(Map<String, dynamic> data)? onHandUpdated;
  Function(Map<String, dynamic> data)? onPlayerCountsUpdated;

  void connect(String serverUrl) {
    socket = io.io(serverUrl, io.OptionBuilder()
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

    // Nuevos eventos de lobby
    socket.on('ready_changed', (data) => onReadyChanged?.call(data['userName'], data['isReady']));
    socket.on('game_started', (_) {
      _bufferedRoundStartedData = null;
      onGameStarted?.call();
    });

    // Eventos del juego de cartas
    socket.on('round_started', (data) {
      final map = Map<String, dynamic>.from(data);
      if (_onRoundStarted != null) {
        _onRoundStarted!(map);
      } else {
        _bufferedRoundStartedData = map;
      }
    });
    socket.on('turn_changed', (data) => onTurnChanged?.call(data['activePlayer'].toString()));
    socket.on('card_drawn', (data) => onCardDrawn?.call(Map<String, dynamic>.from(data)));
    socket.on('card_discarded', (data) => onCardDiscarded?.call(Map<String, dynamic>.from(data)));
    socket.on('card_burned', (data) => onCardBurned?.call(Map<String, dynamic>.from(data)));
    socket.on('power_activated', (data) => onPowerActivated?.call(Map<String, dynamic>.from(data)));
    socket.on('parity_resolved', (data) => onParityResolved?.call(Map<String, dynamic>.from(data)));
    socket.on('private_peek_result', (data) => onPrivatePeek?.call(Map<String, dynamic>.from(data)));
    socket.on('round_ended', (data) => onRoundEnded?.call(Map<String, dynamic>.from(data)));
    socket.on('hand_updated', (data) => onHandUpdated?.call(Map<String, dynamic>.from(data)));
    socket.on('player_counts_updated', (data) => onPlayerCountsUpdated?.call(Map<String, dynamic>.from(data)));
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

  // ==========================================
  // EMISORES DE ACCIONES DEL JUEGO DE CARTAS
  // ==========================================

  /// Robar carta: 'deck' (mazo) o 'discard' (descarte)
  void drawCard(String from) {
    if (currentRoom != null) {
      socket.emit('draw_card', {'roomCode': currentRoom, 'from': from, 'playerName': myName});
    }
  }

  /// Jugar carta robada: 'SWAP' o 'DISCARD'
  void playDrawnCard(String action, int? targetSlotIndex) {
    if (currentRoom != null) {
      socket.emit('play_drawn_card', {
        'roomCode': currentRoom,
        'action': action,
        'targetSlotIndex': targetSlotIndex,
        'playerName': myName,
      });
    }
  }

  /// Utilizar poder de 7, 8 o 9
  void usePower(String powerType, {int? mySlot, String? targetPlayer, int? targetSlot}) {
    if (currentRoom != null) {
      socket.emit('use_power', {
        'roomCode': currentRoom,
        'powerType': powerType,
        'mySlot': mySlot,
        'targetPlayer': targetPlayer,
        'targetSlot': targetSlot,
        'playerName': myName,
      });
    }
  }

  /// Decidir no usar poder
  void skipPower() {
    if (currentRoom != null) {
      socket.emit('skip_power', {'roomCode': currentRoom, 'playerName': myName});
    }
  }

  /// Cantar paridad (enviado tras armar botón y tocar carta)
  void claimParity(String targetPlayer, int slotIndex) {
    if (currentRoom != null && myName != null) {
      socket.emit('claim_parity', {
        'roomCode': currentRoom,
        'caller': myName,
        'targetPlayer': targetPlayer,
        'slotIndex': slotIndex,
      });
    }
  }

  /// Cantar "Soy el que tiene menos cartas"
  void callLowest() {
    if (currentRoom != null && myName != null) {
      socket.emit('call_lowest', {'roomCode': currentRoom, 'playerName': myName});
    }
  }

  /// Solicitar siguiente ronda
  void requestNextRound() {
    if (currentRoom != null) {
      socket.emit('next_round', {'roomCode': currentRoom});
    }
  }

  /// Solicitar sincronización del estado actual del juego
  void requestGameSync() {
    if (currentRoom != null && myName != null) {
      socket.emit('get_game_state', {'roomCode': currentRoom, 'playerName': myName});
    }
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}