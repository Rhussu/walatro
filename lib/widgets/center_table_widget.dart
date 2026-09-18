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
  final VoidCallback? onSkipPower;
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
    this.onSkipPower,
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
    final isPowerChoice = gameState.phase == GamePhase.powerChoice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Zonas Principales: Mazo de Robo | Carta en Mano | Mazo de Descarte
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. ZONA MAZO DE ROBO (Azul Cibernético)
              _buildDrawDeck(canDrawDeck),
              const SizedBox(width: 18),

              // 2. CARTA EN MANO (Pedestal Dorado en Tránsito)
              if (gameState.phase == GamePhase.cardDrawn && gameState.drawnCard != null) ...[
                _buildDrawnCardPedestal(),
                const SizedBox(width: 18),
              ],

              // 3. ZONA MAZO DE DESCARTE (Fuego / Quemado)
              _buildDiscardDeck(topDiscard, canPickDiscard),
            ],
          ),
          const SizedBox(height: 12),

          // Banner de Poder Activo en la Mesa (si estamos en powerChoice)
          if (isPowerChoice && gameState.pendingPowerCard != null) ...[
            _buildPowerChoiceBanner(gameState.pendingPowerCard!),
            const SizedBox(height: 8),
          ],

          // Botón especial de armado de Paridad
          if (!isPowerChoice) ...[
            _buildParityArmButton(),
          ],

          // Botón Cantar Menor (fase de robo)
          if (canCallLow) ...[
            const SizedBox(height: 8),
            RetroButton(
              text: '★ SOY EL QUE TIENE MENOS CARTAS ★',
              color: Colors.purple.shade700,
              onPressed: onCallLowest,
            ),
          ],

          // Opciones al tener carta robada en mano
          if (gameState.phase == GamePhase.cardDrawn && isMyTurn) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: RetroButton(
                    text: 'BOTAR DIRECTO ⬇️',
                    color: Colors.redAccent.shade700,
                    onPressed: onDiscardDrawn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withAlpha(220),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      'O TOCA UNA DE TUS CARTAS PARA CAMBIARLA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  /// 1. Mazo de robo con estética cibernética azul
  Widget _buildDrawDeck(bool canDraw) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: canDraw ? onDrawDeck : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canDraw ? Colors.cyanAccent : const Color(0xFF3B82F6),
                width: canDraw ? 3 : 2,
              ),
              boxShadow: canDraw
                  ? [
                      const BoxShadow(
                        color: Colors.cyanAccent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                      )
                    ],
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
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: canDraw ? Colors.cyanAccent : Colors.blue.shade700,
            ),
          ),
          child: Column(
            children: [
              Text(
                'MAZO: ${gameState.drawPileCount}',
                style: TextStyle(
                  color: canDraw ? Colors.cyanAccent : Colors.white70,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              if (canDraw)
                const Text(
                  'TOCA PARA ROBAR',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Carta robada con transición animada y pedestal dorado
  Widget _buildDrawnCardPedestal() {
    // Si se robó del mazo viene de la izquierda (-0.8), si vino del descarte viene de la derecha (0.8)
    final double initialOffsetX = (gameState.drawnFrom == 'discard') ? 0.8 : -0.8;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(initialOffsetX * 40 * (1.0 - val), 0),
          child: Transform.scale(
            scale: 0.85 + (val * 0.15),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1B03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amberAccent, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.amberAccent,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: PlayingCardWidget(
              card: gameState.drawnCard,
              width: 76,
              height: 108,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade900,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.yellowAccent, width: 1),
            ),
            child: const Text(
              '⭐ EN MANO (ROBADA) ⭐',
              style: TextStyle(
                color: Colors.yellowAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Mazo de descarte con efecto de fuego y exhibición de carta quemada
  Widget _buildDiscardDeck(CardModel? topDiscard, bool canPick) {
    final isBurned = topDiscard?.isBurned == true;
    final hasUnderlyingCard = gameState.discardPile.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: canPick ? onDrawDiscard : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Efecto de carta subyacente quemada apilada detrás si hay más cartas en el descarte
              if (hasUnderlyingCard)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 76,
                    height: 108,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F1604),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepOrange.shade900, width: 1.5),
                    ),
                  ),
                ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isBurned ? const Color(0xFF1E0A03) : const Color(0xFF2A1208),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canPick
                        ? Colors.greenAccent
                        : (isBurned ? Colors.deepOrangeAccent : Colors.orangeAccent),
                    width: canPick ? 3 : (isBurned ? 2.5 : 1.5),
                  ),
                  boxShadow: canPick
                      ? [
                          const BoxShadow(
                            color: Colors.greenAccent,
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : (isBurned
                          ? [
                              BoxShadow(
                                color: Colors.deepOrange.withAlpha(160),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : []),
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
                            'DESCARTE\nVACÍO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontFamily: 'Courier',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isBurned ? Colors.deepOrangeAccent : Colors.orange.shade800,
            ),
          ),
          child: Column(
            children: [
              Text(
                isBurned
                    ? '🔥 QUEMADA (INACTIVA)'
                    : (canPick ? '⚡ DISPONIBLE' : 'DESCARTE'),
                style: TextStyle(
                  color: isBurned
                      ? Colors.deepOrangeAccent
                      : (canPick ? Colors.greenAccent : Colors.orangeAccent),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              if (canPick)
                const Text(
                  'TOCA PARA ROBAR',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Banner interactivo en mesa durante selección de poder
  Widget _buildPowerChoiceBanner(CardModel card) {
    String instruction = '';
    Color bannerColor = Colors.cyan;

    if (card.rank == CardRank.seven) {
      instruction = 'PODER 7: Toca una de tus cartas para mirarla';
      bannerColor = Colors.cyanAccent;
    } else if (card.rank == CardRank.eight) {
      instruction = 'PODER 8: Toca una carta de un rival para mirarla';
      bannerColor = Colors.greenAccent;
    } else if (card.rank == CardRank.nine) {
      instruction = 'PODER 9: Toca una carta propia y luego una rival';
      bannerColor = Colors.amberAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withAlpha(120),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: bannerColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      color: bannerColor,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSkipPower != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: onSkipPower,
              child: const Text(
                'SALTAR ⏭️',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParityArmButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: RetroButton(
        text: isParityArmed
            ? '🔥 PARIDAD ARMADA: TOCA CUALQUIER CARTA - CANCELAR 🔥'
            : '⚡ ARMAR PARIDAD ⚡',
        color: isParityArmed ? Colors.redAccent.shade700 : const Color(0xFFD97706),
        onPressed: onToggleParity,
      ),
    );
  }
}
