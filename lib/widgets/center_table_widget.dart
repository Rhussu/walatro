import 'package:flutter/material.dart';
import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/widgets/playing_card_widget.dart';
import 'package:walatro/widgets/retro_ui.dart';

class CenterTableWidget extends StatelessWidget {
  final GameState gameState;
  final bool isMyTurn;
  final bool isParityArmed;
  final VoidCallback onDrawDeck;
  final VoidCallback onDrawDiscard;
  final VoidCallback onToggleParity;
  final VoidCallback onDiscardDrawn;
  final VoidCallback onCallLowest;
  final int? selectedSlotToSwap;

  const CenterTableWidget({
    super.key,
    required this.gameState,
    required this.isMyTurn,
    required this.isParityArmed,
    required this.onDrawDeck,
    required this.onDrawDiscard,
    required this.onToggleParity,
    required this.onDiscardDrawn,
    required this.onCallLowest,
    this.selectedSlotToSwap,
  });

  @override
  Widget build(BuildContext context) {
    final topDiscard = gameState.topDiscard;
    final canPickDiscard = isMyTurn &&
        gameState.phase == GamePhase.playerTurn &&
        gameState.canDrawFromDiscard;

    final canDrawDeck = isMyTurn && gameState.phase == GamePhase.playerTurn;
    final canCallLow = isMyTurn && gameState.phase == GamePhase.playerTurn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mazo de robo, Carta robada (si aplica) y Mazo de descarte
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Mazo de robo
              _buildDrawDeck(canDrawDeck),
              const SizedBox(width: 20),

              // Carta robada en mano (si el jugador activo acaba de robar)
              if (gameState.phase == GamePhase.cardDrawn && gameState.drawnCard != null) ...[
                _buildDrawnCardSection(),
                const SizedBox(width: 20),
              ],

              // 2. Mazo de descarte
              _buildDiscardDeck(topDiscard, canPickDiscard),
            ],
          ),
          const SizedBox(height: 12),

          // Botón especial de armado de Paridad
          _buildParityArmButton(),

          // Acciones de turno (Cantar menor o Descartar la carta robada)
          if (canCallLow) ...[
            const SizedBox(height: 8),
            RetroButton(
              text: '★ SOY EL QUE TIENE MENOS CARTAS ★',
              color: Colors.purple.shade700,
              onPressed: onCallLowest,
            ),
          ],

          if (gameState.phase == GamePhase.cardDrawn && isMyTurn) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: RetroButton(
                    text: 'BOTAR DIRECTO',
                    color: Colors.redAccent.shade700,
                    onPressed: onDiscardDrawn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withAlpha(200),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      'O TOCA UNA DE TUS CARTAS PARA CAMBIARLA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawDeck(bool canDraw) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: canDraw ? onDrawDeck : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: canDraw ? Colors.greenAccent : Colors.white54,
                width: canDraw ? 3 : 1.5,
              ),
              boxShadow: canDraw
                  ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
            child: PlayingCardWidget(
              card: CardModel(
                id: 'deck_cover',
                suit: CardSuit.spades,
                rank: CardRank.ace,
                isFaceUp: false,
              ),
              width: 76,
              height: 108,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'MAZO: ${gameState.drawPileCount}',
            style: TextStyle(
              color: canDraw ? Colors.greenAccent : Colors.white70,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawnCardSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.yellowAccent, blurRadius: 10)],
                ),
                child: PlayingCardWidget(
                  card: gameState.drawnCard,
                  width: 76,
                  height: 108,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ROBADA',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscardDeck(CardModel? topDiscard, bool canPick) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: canPick ? onDrawDiscard : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: canPick
                    ? Colors.greenAccent
                    : (topDiscard?.isBurned == true ? Colors.deepOrangeAccent : Colors.white54),
                width: canPick ? 3 : 1.5,
              ),
              boxShadow: canPick
                  ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
            child: topDiscard != null
                ? PlayingCardWidget(
                    card: topDiscard,
                    width: 76,
                    height: 108,
                  )
                : Container(
                    width: 76,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'VACÍO',
                        style: TextStyle(color: Colors.white38, fontFamily: 'Courier', fontSize: 11),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: topDiscard?.isBurned == true ? Colors.deepOrangeAccent : Colors.white24,
            ),
          ),
          child: Text(
            topDiscard?.isBurned == true ? '🔥 QUEMADA' : 'DESCARTE',
            style: TextStyle(
              color: topDiscard?.isBurned == true
                  ? Colors.deepOrangeAccent
                  : (canPick ? Colors.greenAccent : Colors.white70),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParityArmButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: RetroButton(
        text: isParityArmed
            ? '🔥 MODO PARIDAD ARMADO (TOCA UNA CARTA) - CANCELAR 🔥'
            : '⚡ ARMAR PARIDAD ⚡',
        color: isParityArmed ? Colors.redAccent.shade700 : const Color(0xFFD97706),
        onPressed: onToggleParity,
      ),
    );
  }
}
