import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walatro/widgets/retro_ui.dart';
import 'package:walatro/models/player.dart'; // Asegúrate de importar el archivo anterior

// ==========================================
// VISTA 1: PEDIR NOMBRE
// ==========================================
class NameInputView extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onStart;

  const NameInputView({super.key, required this.controller, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return RetroContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'INSERTE MONEDA\n(O TU NOMBRE)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Courier', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.black54,
              hintText: 'PLAYER 1',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2), borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent, width: 2), borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: 20),
          RetroButton(
            text: 'START',
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onStart(controller.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VISTA 2: CREAR O UNIRSE A SALA
// ==========================================
class LobbyActionsView extends StatelessWidget {
  final String playerName;
  final TextEditingController roomCodeController;
  final VoidCallback onCreateRoom;
  final Function(String) onJoinRoom;

  const LobbyActionsView({
    super.key,
    required this.playerName,
    required this.roomCodeController,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    return RetroContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('HOLA, $playerName', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          RetroButton(
            text: 'NUEVA PARTIDA',
            onPressed: onCreateRoom,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('- O -', style: TextStyle(color: Colors.white70, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          ),
          TextField(
            controller: roomCodeController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 5),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(4)],
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.black54,
              hintText: 'CODE',
              hintStyle: TextStyle(color: Colors.white30, letterSpacing: 0),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2), borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent, width: 2), borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: 10),
          RetroButton(
            text: 'UNIRSE',
            color: Colors.orange,
            onPressed: () {
              final code = roomCodeController.text.trim();
              if (code.length == 4) {
                onJoinRoom(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código debe tener 4 letras.')));
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VISTA 3: LA SALA CON EL CHAT Y READY
// ==========================================
class RoomChatView extends StatelessWidget {
  final String myName;
  final List<Player> players;
  final List<Map<String, String>> chatMessages;
  final TextEditingController chatController;
  final VoidCallback onSendChat;
  final Function(bool) onSetReady;
  final VoidCallback onStartGame;
  final FocusNode chatFocusNode;

  const RoomChatView({
    super.key,
    required this.myName,
    required this.players,
    required this.chatMessages,
    required this.chatController,
    required this.chatFocusNode,
    required this.onSendChat,
    required this.onSetReady,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    // Encontramos quién eres tú para saber tus permisos
    final me = players.firstWhere((p) => p.name == myName, orElse: () => Player(name: myName, isHost: false, isReady: false));
    // Comprobamos si TODOS están listos (excluyendo a ti si eres el dueño, porque el dueño siempre está listo)
    final allReady = players.every((p) => p.isReady);

    return Column(
      children: [
        // --- BOTONAZO DE ACCIÓN (EMPEZAR O READY) ---
        if (me.isHost)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: RetroButton(
              text: allReady ? 'EMPEZAR JUEGO' : 'ESPERANDO JUGADORES...',
              color: allReady ? Colors.green : Colors.grey,
              onPressed: () {
                if (allReady) onStartGame();
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: RetroButton(
              text: me.isReady ? 'CANCELAR READY' : '¡ESTOY LISTO!',
              color: me.isReady ? Colors.orange : Colors.green,
              onPressed: () => onSetReady(!me.isReady), // Alterna el estado
            ),
          ),

        // --- LISTA DE JUGADORES ---
        Container(
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF2B2B2B), border: Border.all(color: Colors.white, width: 3)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isMe = player.name == myName;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blueGrey.shade800 : Colors.black54,
                  border: Border.all(
                    color: player.isReady ? Colors.greenAccent : Colors.white30, 
                    width: 2
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Iconito: Corona para el host, ticket para los ready
                    if (player.isHost) 
                      const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.star, color: Colors.yellow, size: 16))
                    else if (player.isReady)
                      const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.check, color: Colors.greenAccent, size: 16)),
                    
                    Text(
                      player.name, 
                      style: TextStyle(
                        color: player.isReady ? Colors.white : Colors.white54, 
                        fontFamily: 'Courier', 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      final isSystem = msg['sender'] == 'Sistema';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          isSystem ? '> ${msg['message']}' : '[${msg['sender']}] ${msg['message']}',
                          style: TextStyle(
                            color: isSystem ? Colors.yellowAccent : Colors.white,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 2))),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController,
                          focusNode: chatFocusNode,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'ESCRIBE...',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.black,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => onSendChat(),
                        ),
                      ),
                      RetroButton(
                        onPressed: onSendChat,
                        fullWidth: false,
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.send, color: Colors.white, size: 24),
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
}