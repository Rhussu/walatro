import 'package:flutter/material.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/widgets/playing_card_widget.dart';
import 'package:walatro/widgets/retro_ui.dart';

class RoundSummaryDialog extends StatelessWidget {
  final GameState gameState;
  final String myPlayerName;
  final VoidCallback onNextRound;

  const RoundSummaryDialog({
    super.key,
    required this.gameState,
    required this.myPlayerName,
    required this.onNextRound,
  });

  @override
  Widget build(BuildContext context) {
    String reasonText = 'FIN DE LA RONDA';
    Color reasonColor = Colors.amberAccent;

    if (gameState.roundEndReason == 'CALLED_LOW') {
      reasonText = '${gameState.roundEndCaller ?? "Alguien"} cantó "Soy el que tiene menos"';
      reasonColor = Colors.cyanAccent;
    } else if (gameState.roundEndReason == 'ZERO_CARDS') {
      reasonText = '¡Un jugador se quedó sin cartas!';
      reasonColor = Colors.greenAccent;
    } else if (gameState.roundEndReason == 'DECK_EMPTY') {
      reasonText = '¡Se agotó el mazo de robo!';
      reasonColor = Colors.redAccent;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: RetroContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              Text(
                'RESULTADOS - RONDA ${gameState.roundNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reasonText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: reasonColor,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Divider(color: Colors.white24, height: 20),

              // Lista de jugadores con sus cartas reveladas y puntajes
              Expanded(
                child: ListView.separated(
                  itemCount: gameState.players.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 16),
                  itemBuilder: (context, index) {
                    final p = gameState.players[index];
                    final isMe = p.name == myPlayerName;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withAlpha(15) : Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isMe ? Colors.yellowAccent : Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMe ? '${p.name} (TÚ)' : p.name,
                                style: TextStyle(
                                  color: isMe ? Colors.yellowAccent : Colors.white,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Ronda: ${p.roundScore} pts | Total: ${p.totalScore} pts',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Cartas reveladas
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (int i = 0; i < p.cards.length; i++)
                                if (p.cards[i] != null) ...[
                                  PlayingCardWidget(
                                    card: p.cards[i]!..isFaceUp = true,
                                    width: 48,
                                    height: 68,
                                  ),
                                ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Botón siguiente ronda
              RetroButton(
                text: 'CONTINUAR / SIGUIENTE RONDA',
                color: Colors.green,
                onPressed: onNextRound,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
