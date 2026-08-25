import 'package:flutter/material.dart';
// Asegúrate de importar el archivo donde guardaste la clase RoomService
import 'package:walatro/services/room_services.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _serverUrl = 'https://walatro.onrender.com';
  final _roomService = RoomService();

  // Controladores de texto
  final _nameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _chatController = TextEditingController();

  // Estado de nuestra UI
  String? myName;
  String? currentRoomCode;
  List<String> players = [];
  List<Map<String, String>> chatMessages = []; // Formato: {'sender': 'Juan', 'message': 'Hola'}

  @override
  void initState() {
    super.initState();
    _setupRoomService();
    _roomService.connect(_serverUrl);
  }

  void _setupRoomService() {
    // Cuando logras entrar a una sala (ya sea creada o unida)
    _roomService.onRoomJoined = (code, users) {
      setState(() {
        currentRoomCode = code;
        players = users;
        chatMessages.add({'sender': 'Sistema', 'message': '¡Entraste a la sala $code!'});
      });
    };

    // Cuando un pobre diablo se une a tu sala
    _roomService.onUserJoined = (userName) {
      setState(() {
        if (!players.contains(userName)) players.add(userName);
        chatMessages.add({'sender': 'Sistema', 'message': '$userName se unió a la fiesta.'});
      });
    };

    // Cuando alguien abandona el barco
    _roomService.onUserLeft = (userName) {
      setState(() {
        players.remove(userName);
        chatMessages.add({'sender': 'Sistema', 'message': '$userName se ha ido.'});
      });
    };

    // Cuando alguien escribe en el chat
    _roomService.onChatMessage = (sender, message) {
      setState(() {
        chatMessages.add({'sender': sender, 'message': message});
      });
    };

    // Si algo explota
    _roomService.onError = (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    _chatController.dispose();
    _roomService.dispose();
    super.dispose();
  }

  // ==========================================
  // CONSTRUCTOR DE LA UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(currentRoomCode != null ? 'Sala: $currentRoomCode' : 'Walatro Lobby'),
      ),
      body: Stack(
        children: [
          // Tu fondito facha
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  // Aquí ocurre la magia de decidir qué pantalla mostrar
                  child: _buildCurrentView(),
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
      return _buildNameInput();
    } else if (currentRoomCode == null) {
      return _buildLobbyActions();
    } else {
      return _buildRoom();
    }
  }

  // 1. PANTALLA PARA PEDIR EL NOMBRE
  Widget _buildNameInput() {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Cómo te llamas?', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                hintText: 'Tu apodo bacán',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  setState(() => myName = _nameController.text.trim());
                }
              },
              child: const Text('Continuar'),
            )
          ],
        ),
      ),
    );
  }

  // 2. PANTALLA PARA CREAR/UNIRSE
  Widget _buildLobbyActions() {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hola, $myName', style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _roomService.createRoom(myName!),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('CREAR NUEVA SALA'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('O', style: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: _roomCodeController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                hintText: 'CÓDIGO DE SALA',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final code = _roomCodeController.text.trim();
                if (code.isNotEmpty) {
                  _roomService.joinRoom(code, myName!);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('UNIRSE'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. PANTALLA DE LA SALA (JUGADORES Y CHAT)
  Widget _buildRoom() {
    return Column(
      children: [
        // Lista de jugadores
        Container(
          height: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Chip(
                  label: Text(players[index]),
                  backgroundColor: players[index] == myName ? Colors.green : Colors.blueGrey,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        
        // El Chat
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      final isMe = msg['sender'] == myName;
                      final isSystem = msg['sender'] == 'Sistema';

                      return Align(
                        alignment: isSystem ? Alignment.center : (isMe ? Alignment.centerRight : Alignment.centerLeft),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSystem ? Colors.transparent : (isMe ? Colors.green.shade800 : Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSystem ? msg['message']! : '${msg['sender']}: ${msg['message']}',
                            style: TextStyle(
                              color: isSystem ? Colors.white54 : Colors.white,
                              fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Input de mensaje
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Escribe algo...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white24,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: _sendChat,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      _roomService.sendChat(text);
      _chatController.clear();
    }
  }
}