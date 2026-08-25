import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para el Clipboard y el InputFormatter
import 'package:walatro/services/room_services.dart';

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

  String? myName;
  String? currentRoomCode;
  List<String> players = [];
  List<Map<String, String>> chatMessages = [];

  // Estado de conexión para el semáforo retro
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
        chatMessages.add({
          'sender': 'Sistema',
          'message': '¡Entraste a la sala $code!',
        });
      });
    };

    _roomService.onUserJoined = (userName) {
      setState(() {
        if (!players.contains(userName)) players.add(userName);
        chatMessages.add({
          'sender': 'Sistema',
          'message': '$userName se unió a la fiesta.',
        });
      });
    };

    _roomService.onUserLeft = (userName) {
      setState(() {
        players.remove(userName);
        chatMessages.add({
          'sender': 'Sistema',
          'message': '$userName se ha ido.',
        });
      });
    };

    _roomService.onChatMessage = (sender, message) {
      setState(() {
        chatMessages.add({'sender': sender, 'message': message});
      });
    };

    _roomService.onError = (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
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
    _roomService.dispose();
    super.dispose();
  }

  // ==========================================
  // WIDGETS RETRO / 8-BIT
  // ==========================================

  // Contenedor estilo bloque clásico
  Widget _retroContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: child,
    );
  }

  // Botón cuadradito
  Widget _retroButton({
    required String text,
    required VoidCallback onPressed,
    Color color = Colors.green,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Courier',
          ),
        ),
      ),
    );
  }

  // El indicador de estado
  Widget _buildStatusIndicator() {
    Color statusColor;
    switch (connectionStatus) {
      case 'connected':
        statusColor = Colors.greenAccent;
        break;
      case 'connecting':
        statusColor = Colors.orangeAccent;
        break;
      case 'disconnected':
      default:
        statusColor = Colors.redAccent;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: statusColor,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ), // Cuadrado 8-bit en vez de círculo
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            _buildStatusIndicator(),
            Text(
              currentRoomCode != null
                  ? 'SALA: $currentRoomCode'
                  : 'WALATRO LOBBY',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
              ),
            ),
            if (currentRoomCode != null)
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: currentRoomCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡CÓDIGO COPIADO!',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
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

  Widget _buildNameInput() {
    return _retroContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'INSERTE MONEDA\n(O TU NOMBRE)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              UpperCaseTextFormatter(),
            ], // ¡Magia para las mayúsculas!
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.black54,
              hintText: 'PLAYER 1',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 20),
          RetroButton(
            text: 'START',
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                setState(() => myName = _nameController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyActions() {
    return _retroContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HOLA, $myName',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 20,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          RetroButton(
            text: 'NUEVA PARTIDA',
            onPressed: () => _roomService.createRoom(myName!),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '- O -',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Courier',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 5,
            ),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(
                4,
              ), // Limita a 4 letras como tu servidor
            ],
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.black54,
              hintText: 'CODE',
              hintStyle: TextStyle(color: Colors.white30, letterSpacing: 0),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          RetroButton(
            text: 'UNIRSE',
            color: Colors.orange,
            onPressed: () {
              final code = _roomCodeController.text.trim();
              if (code.length == 4) {
                _roomService.joinRoom(code, myName!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El código debe tener 4 letras.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoom() {
    return Column(
      children: [
        // Lista de jugadores retro
        Container(
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final isMe = players[index] == myName;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.green.shade700
                      : Colors.blueGrey.shade700,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    players[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Chat retro
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
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
                          isSystem
                              ? '> ${msg['message']}'
                              : '[${msg['sender']}] ${msg['message']}',
                          style: TextStyle(
                            color: isSystem
                                ? Colors.yellowAccent
                                : Colors.white,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'ESCRIBE...',
                            hintStyle: TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: Colors.black,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                      // Al lado del TextField del chat, reemplaza el GestureDetector por:
                      RetroButton(
                        onPressed: _sendChat,
                        fullWidth: false, // Para que no ocupe toda la pantalla
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
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

// Clase mágica para forzar mayúsculas mientras el usuario escribe
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ==========================================
// BOTÓN RETRO INTERACTIVO
// ==========================================
class RetroButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback onPressed;
  final Color color;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;

  const RetroButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.color = Colors.green,
    this.fullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // ¡Aquí activamos la manito del cursor!
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 50,
          ), // Animación ultra rápida para el "click"
          width: widget.fullWidth ? double.infinity : null,
          margin: EdgeInsets.only(
            // El truco de la maquinita: lo desplazamos 4 píxeles cuando se presiona
            top: _isPressed ? 4 : 0,
            left: _isPressed ? 4 : 0,
            bottom: _isPressed ? 0 : 4,
            right: _isPressed ? 0 : 4,
          ),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: _isPressed
                ? [] // Al hundirse, desaparece la sombra
                : [const BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child:
              widget.child ??
              Text(
                widget.text ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Courier',
                ),
              ),
        ),
      ),
    );
  }
}
