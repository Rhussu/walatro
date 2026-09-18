import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walatro/screens/game.dart'; 
import 'package:walatro/services/room_services.dart';
// ¡Asegúrate de ajustar los imports a tus carpetas correctas!
import 'package:walatro/widgets/lobby_views.dart';
import 'package:walatro/models/player.dart'; // Asegúrate de importar el archivo anterior

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _serverUrl = 'https://walatro.onrender.com';
  final _roomService = RoomService();

  final _nameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _chatController = TextEditingController();
  final _chatFocusNode = FocusNode(); // 👈 1. Agrega esto

  String? myName;
  String? currentRoomCode;
  List<Player> players = [];
  List<Map<String, String>> chatMessages = [];
  String connectionStatus = 'connecting';

  @override
  void initState() {
    super.initState();
    _setupRoomService();
    _roomService.connect(_serverUrl);
    _roomService.onConnectionStatus?.call('connecting');
  }

  void _setupRoomService() {
    _roomService.onConnectionStatus = (status) {
      if (mounted) setState(() => connectionStatus = status);
    };

    _roomService.onRoomJoined = (code, users) {
      setState(() {
        currentRoomCode = code;
        players = users;
        chatMessages.add({'sender': 'Sistema', 'message': '¡Entraste a la sala $code!'});
      });
    };

    _roomService.onUserJoined = (user) { // <- Recibimos un Player
      setState(() {
        if (!players.any((p) => p.name == user.name)) players.add(user);
        chatMessages.add({'sender': 'Sistema', 'message': '${user.name} se unió a la fiesta.'});
      });
    };

    _roomService.onUserLeft = (userName) {
      setState(() {
        players.removeWhere((p) => p.name == userName); // <- Buscamos por nombre
        chatMessages.add({'sender': 'Sistema', 'message': '$userName se ha ido.'});
      });
    };

    _roomService.onChatMessage = (sender, message) {
      setState(() => chatMessages.add({'sender': sender, 'message': message}));
    };

    _roomService.onReadyChanged = (userName, isReady) {
      setState(() {
        final index = players.indexWhere((p) => p.name == userName);
        if (index != -1) players[index].isReady = isReady;
      });
    };

    _roomService.onGameStarted = () {
      // Como todos siguen conectados al Socket, pasamos a la nueva pantalla
      // Podemos mandar el roomService por parámetro para no perder la conexión.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameScreen(roomService: _roomService, myName: myName)),
      );
    };

    _roomService.onError = (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _roomService.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      _roomService.sendChat(text);
      _chatController.clear();
    }
    // 👈 3. ¡La magia! Le devolvemos el foco al campo de texto
    _chatFocusNode.requestFocus(); 
  }

  Widget _buildStatusIndicator() {
    Color statusColor = {
      'connected': Colors.greenAccent,
      'connecting': Colors.orangeAccent,
    }[connectionStatus] ?? Colors.redAccent;

    return Container(
      width: 16, height: 16,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: statusColor, border: Border.all(color: Colors.black, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            _buildStatusIndicator(),
            Text(
              currentRoomCode != null ? 'SALA: $currentRoomCode' : 'WALATRO LOBBY',
              style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))]),
            ),
            if (currentRoomCode != null)
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: currentRoomCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡CÓDIGO COPIADO!', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentView(), // ¡Mira qué limpio quedó esto!
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (myName == null) {
      return NameInputView(
        controller: _nameController,
        onStart: (name) => setState(() => myName = name),
      );
    } else if (currentRoomCode == null) {
      return LobbyActionsView(
        playerName: myName!,
        roomCodeController: _roomCodeController,
        onCreateRoom: () => _roomService.createRoom(myName!),
        onJoinRoom: (code) => _roomService.joinRoom(code, myName!),
      );
    } else {
      return RoomChatView(
        myName: myName!,
        players: players,
        chatMessages: chatMessages,
        chatController: _chatController,
        chatFocusNode: _chatFocusNode, // 👈 4. Se lo pasamos a la vista
        onSendChat: _sendChat,
        onSetReady: (isReady) => _roomService.setReady(isReady),
        onStartGame: () => _roomService.startGame(),
      );
    }
  }
}