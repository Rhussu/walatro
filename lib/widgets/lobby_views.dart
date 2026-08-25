import 'package:flutter/material.dart';

class LobbyActionsView extends StatelessWidget {
  const LobbyActionsView({
    required this.connected,
    required this.enabled,
    required this.connectingToRoom,
    required this.onCreate,
    required this.onJoin,
    super.key,
  });

  final bool connected;
  final bool enabled;
  final bool connectingToRoom;
  final VoidCallback? onCreate;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sala de juego',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 28),
        _ActionButton(
          icon: Icons.add_home,
          label: 'Crear sala',
          onPressed: enabled ? onCreate : null,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.meeting_room,
          label: 'Unirse con código',
          onPressed: enabled ? onJoin : null,
        ),
        const SizedBox(height: 18),
        Text(
          connectingToRoom
              ? 'Conectando a la sala...'
              : connected
              ? 'Conectado al servidor'
              : 'Conectando...',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class RoomView extends StatelessWidget {
  const RoomView({
    required this.isHost,
    required this.roomCode,
    required this.players,
    required this.messages,
    required this.channelReady,
    required this.messageController,
    required this.onSend,
    super.key,
  });

  final bool isHost;
  final String roomCode;
  final List<String> players;
  final List<String> messages;
  final bool channelReady;
  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              isHost ? 'Sala creada' : 'Te uniste a la sala',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              roomCode,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            if (isHost) const Text('Comparte este código con tus amigos.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Jugadores conectados (${players.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: players
                    .map(
                      (name) => Chip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: Text(name),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 32),
            SizedBox(
              height: 220,
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        channelReady
                            ? 'Aún no hay mensajes.'
                            : 'Esperando conexión...',
                      ),
                    )
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) => Text(messages[index]),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    enabled: channelReady,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: channelReady ? onSend : null,
                  icon: const Icon(Icons.send),
                  tooltip: 'Enviar mensaje',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
