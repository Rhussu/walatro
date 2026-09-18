import 'package:flutter/material.dart';
import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/player_game_state.dart';
import 'package:walatro/widgets/playing_card_widget.dart';

class PlayerBoardWidget extends StatelessWidget {
  final PlayerGameState player;
  final bool isLocalPlayer;
  final bool isActiveTurn;
  final bool isParityArmed;
  final int? selectedSlot;
  final Function(int slotIndex)? onCardTapped;
  final double cardWidth;
  final double cardHeight;

  const PlayerBoardWidget({
    super.key,
    required this.player,
    required this.isLocalPlayer,
    this.isActiveTurn = false,
    this.isParityArmed = false,
    this.selectedSlot,
    this.onCardTapped,
    this.cardWidth = 68,
    this.cardHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActiveTurn
              ? Colors.amberAccent
              : (isParityArmed ? Colors.redAccent : Colors.white24),
          width: isActiveTurn ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isActiveTurn)
            const BoxShadow(
              color: Colors.amberAccent,
              blurRadius: 8,
              spreadRadius: 1,
            )
          else if (isParityArmed)
            const BoxShadow(
              color: Colors.redAccent,
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de información del jugador
          _buildPlayerHeader(),
          const SizedBox(height: 8),

          // Cuadrícula fija de cartas (2x2)
          _buildCardsGrid(),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActiveTurn ? Colors.greenAccent : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isLocalPlayer ? '${player.name} (TÚ)' : player.name,
              style: TextStyle(
                color: isLocalPlayer ? Colors.yellowAccent : Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '${player.cardCount} cartas | ${player.totalScore} pts',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Courier',
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsGrid() {
    // Si tiene 4 cartas o menos, mostramos fila superior (0, 1) e inferior (2, 3)
    final cards = player.cards;
    CardModel? card0 = cards.isNotEmpty ? cards[0] : null;
    CardModel? card1 = cards.length > 1 ? cards[1] : null;
    CardModel? card2 = cards.length > 2 ? cards[2] : null;
    CardModel? card3 = cards.length > 3 ? cards[3] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlotCard(0, card0),
            const SizedBox(width: 8),
            _buildSlotCard(1, card1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlotCard(2, card2),
            const SizedBox(width: 8),
            _buildSlotCard(3, card3),
          ],
        ),
        // Si acumuló cartas de penalización extras (más de 4 cartas)
        if (cards.length > 4) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 4; i < cards.length; i++)
                _buildSlotCard(i, cards[i]),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSlotCard(int slotIndex, CardModel? card) {
    bool isSelectable = onCardTapped != null && (card != null || isLocalPlayer);

    return PlayingCardWidget(
      card: card,
      slotIndex: slotIndex,
      width: cardWidth,
      height: cardHeight,
      isSelected: selectedSlot == slotIndex,
      isSelectable: isParityArmed || isSelectable,
      onTap: () {
        if (onCardTapped != null) {
          onCardTapped!(slotIndex);
        }
      },
    );
  }
}
