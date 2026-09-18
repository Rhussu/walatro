import 'dart:math';
import 'package:flutter/material.dart';
import 'package:walatro/models/card_model.dart';

class PlayingCardWidget extends StatefulWidget {
  final CardModel? card;
  final int? slotIndex;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool forceBurnEffect;
  final bool forcePowerEffect;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.slotIndex,
    this.isSelected = false,
    this.isSelectable = false,
    this.onTap,
    this.width = 76,
    this.height = 108,
    this.forceBurnEffect = false,
    this.forcePowerEffect = false,
  });

  @override
  State<PlayingCardWidget> createState() => _PlayingCardWidgetState();
}

class _PlayingCardWidgetState extends State<PlayingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.card == null) {
      return _buildEmptySlot();
    }

    final card = widget.card!;
    final isBurned = card.isBurned || widget.forceBurnEffect;
    final isPowerGlow = card.powerUsed || widget.forcePowerEffect;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Decoración y auras dinámicas
        List<BoxShadow> shadows = [];

        if (isBurned) {
          // Aura de fuego ardiente y cenizas
          final glowVal = 3.0 + _controller.value * 6.0;
          shadows = [
            BoxShadow(
              color: Colors.deepOrangeAccent.withAlpha((180 + (_controller.value * 75)).toInt()),
              blurRadius: glowVal * 2,
              spreadRadius: glowVal,
            ),
            BoxShadow(
              color: Colors.redAccent.withAlpha((150 + (_controller.value * 80)).toInt()),
              blurRadius: glowVal,
              spreadRadius: 2,
            ),
          ];
        } else if (isPowerGlow) {
          // Aura cian/dorada mística de poder utilizado
          final glowVal = 4.0 + _controller.value * 5.0;
          shadows = [
            BoxShadow(
              color: Colors.cyanAccent.withAlpha((180 + (_controller.value * 70)).toInt()),
              blurRadius: glowVal * 2,
              spreadRadius: glowVal,
            ),
            const BoxShadow(
              color: Colors.amberAccent,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ];
        } else if (widget.isSelected) {
          shadows = [
            const BoxShadow(
              color: Colors.yellowAccent,
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ];
        } else if (widget.isSelectable) {
          shadows = [
            BoxShadow(
              color: Colors.greenAccent.withAlpha((100 + (_controller.value * 120)).toInt()),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ];
        } else {
          shadows = const [
            BoxShadow(color: Colors.black, offset: Offset(3, 4)),
          ];
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: shadows,
            ),
            child: Stack(
              children: [
                card.isFaceUp ? _buildFaceUpCard(card) : _buildFaceDownCard(),
                if (isBurned) _buildBurnOverlay(),
                if (isPowerGlow) _buildPowerGlowOverlay(),
                if (widget.slotIndex != null) _buildSlotBadge(widget.slotIndex!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white24,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, color: Colors.white24, size: 24),
            if (widget.slotIndex != null)
              Text(
                'SLOT ${widget.slotIndex}',
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceUpCard(CardModel card) {
    Color cardColor = card.isRed ? const Color(0xFFD32F2F) : const Color(0xFF1B1B1B);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF), // Color pergamino/retro
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isSelected ? Colors.yellowAccent : const Color(0xFF2C2C2C),
          width: widget.isSelected ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Esquina superior izquierda
          Row(
            children: [
              Text(
                card.rankLabel,
                style: TextStyle(
                  color: cardColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 2),
              Text(
                card.suitSymbol,
                style: TextStyle(color: cardColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Centro con símbolo grande o valor especial
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: cardColor.withAlpha(220),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (card.rank == CardRank.king && card.suit == CardSuit.spades)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade900,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      '-1 PT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (card.canTriggerPower)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PODER ${card.rankLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Esquina inferior derecha (invertida)
          Transform.rotate(
            angle: pi,
            child: Row(
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  card.suitSymbol,
                  style: TextStyle(color: cardColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceDownCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Azul retro arcade
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isSelected ? Colors.yellowAccent : Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amberAccent, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.games, color: Colors.amberAccent, size: 26),
          ),
        ),
      ),
    );
  }

  /// Efecto visual de quemado por fuego en paridad
  Widget _buildBurnOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.deepOrange.withAlpha((190 + (_controller.value * 65)).toInt()),
                Colors.amber.withAlpha(120),
                Colors.black.withAlpha(70),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.amberAccent,
                  size: 34 + (_controller.value * 6),
                ),
                const Text(
                  'QUEMADA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Efecto visual de aura de poder utilizado
  Widget _buildPowerGlowOverlay() {
    return Positioned(
      top: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.shade700,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent,
              blurRadius: 6 + (_controller.value * 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildSlotBadge(int index) {
    return Positioned(
      top: 3,
      left: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white54, width: 1),
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
