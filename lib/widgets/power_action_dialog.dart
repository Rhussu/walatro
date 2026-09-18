import 'package:flutter/material.dart';
import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/widgets/playing_card_widget.dart';
import 'package:walatro/widgets/retro_ui.dart';

class PowerActionDialog extends StatefulWidget {
  final CardModel powerCard;
  final GameState gameState;
  final String myPlayerName;
  final Function(String powerType, {int? mySlot, String? targetPlayer, int? targetSlot}) onUsePower;
  final VoidCallback onSkipPower;

  const PowerActionDialog({
    super.key,
    required this.powerCard,
    required this.gameState,
    required this.myPlayerName,
    required this.onUsePower,
    required this.onSkipPower,
  });

  @override
  State<PowerActionDialog> createState() => _PowerActionDialogState();
}

class _PowerActionDialogState extends State<PowerActionDialog> {
  int? _selectedMySlot;
  String? _selectedTargetPlayer;
  int? _selectedTargetSlot;

  @override
  void initState() {
    super.initState();
    final opponents = widget.gameState.players
        .where((p) => p.name != widget.myPlayerName)
        .toList();
    if (opponents.isNotEmpty) {
      _selectedTargetPlayer = opponents.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.powerCard.rank;
    String title = '';
    String description = '';
    String powerType = '';

    if (rank == CardRank.seven) {
      title = 'PODER DEL 7: ESPIAR CARTA PROPIA';
      description = 'Selecciona una de tus 4 cartas para verla en secreto durante unos segundos.';
      powerType = 'PEEK_OWN';
    } else if (rank == CardRank.eight) {
      title = 'PODER DEL 8: ESPIAR CARTA RIVAL';
      description = 'Selecciona un rival y una de sus cartas para verla en secreto.';
      powerType = 'PEEK_OTHER';
    } else if (rank == CardRank.nine) {
      title = 'PODER DEL 9: INTERCAMBIAR Y VER AMBAS';
      description = 'Selecciona una de tus cartas y una de un rival para intercambiarlas viendo ambas.';
      powerType = 'SWAP';
    }

    final myPlayer = widget.gameState.getPlayer(widget.myPlayerName);
    final opponents = widget.gameState.players
        .where((p) => p.name != widget.myPlayerName)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: RetroContainer(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con carta de poder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlayingCardWidget(
                      card: widget.powerCard,
                      width: 50,
                      height: 70,
                      forcePowerEffect: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Courier',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),

                // Selector de ranura propia (si es 7 o 9)
                if (rank == CardRank.seven || rank == CardRank.nine) ...[
                  const Text(
                    'ELIGE TU CARTA:',
                    style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (myPlayer != null)
                        for (int i = 0; i < myPlayer.cards.length; i++)
                          if (myPlayer.cards[i] != null)
                            ChoiceChip(
                              label: Text('SLOT $i', style: const TextStyle(fontFamily: 'Courier')),
                              selected: _selectedMySlot == i,
                              selectedColor: Colors.amberAccent,
                              backgroundColor: Colors.black45,
                              labelStyle: TextStyle(
                                color: _selectedMySlot == i ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setState(() => _selectedMySlot = i),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Selector de rival y ranura ajena (si es 8 o 9)
                if (rank == CardRank.eight || rank == CardRank.nine) ...[
                  const Text(
                    'ELIGE RIVAL Y SU CARTA:',
                    style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var op in opponents)
                        ChoiceChip(
                          label: Text(op.name, style: const TextStyle(fontFamily: 'Courier')),
                          selected: _selectedTargetPlayer == op.name,
                          selectedColor: Colors.cyanAccent,
                          backgroundColor: Colors.black45,
                          labelStyle: TextStyle(
                            color: _selectedTargetPlayer == op.name ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() {
                            _selectedTargetPlayer = op.name;
                            _selectedTargetSlot = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedTargetPlayer != null) ...[
                    Builder(builder: (context) {
                      final targetP = widget.gameState.getPlayer(_selectedTargetPlayer!);
                      return Wrap(
                        spacing: 8,
                        children: [
                          if (targetP != null)
                            for (int i = 0; i < targetP.cards.length; i++)
                              if (targetP.cards[i] != null)
                                ChoiceChip(
                                  label: Text('CARTA $i', style: const TextStyle(fontFamily: 'Courier')),
                                  selected: _selectedTargetSlot == i,
                                  selectedColor: Colors.cyanAccent,
                                  backgroundColor: Colors.black45,
                                  labelStyle: TextStyle(
                                    color: _selectedTargetSlot == i ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (_) => setState(() => _selectedTargetSlot = i),
                                ),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                ],

                // Botones de acción: USAR PODER o SALTAR PODER
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        text: 'SALTAR PODER',
                        color: Colors.grey.shade800,
                        onPressed: widget.onSkipPower,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RetroButton(
                        text: 'ACTIVAR PODER',
                        color: _canConfirmPower(rank) ? Colors.green : Colors.grey.shade700,
                        onPressed: () {
                          if (_canConfirmPower(rank)) {
                            widget.onUsePower(
                              powerType,
                              mySlot: _selectedMySlot,
                              targetPlayer: _selectedTargetPlayer,
                              targetSlot: _selectedTargetSlot,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canConfirmPower(CardRank rank) {
    if (rank == CardRank.seven) {
      return _selectedMySlot != null;
    } else if (rank == CardRank.eight) {
      return _selectedTargetPlayer != null && _selectedTargetSlot != null;
    } else if (rank == CardRank.nine) {
      return _selectedMySlot != null &&
          _selectedTargetPlayer != null &&
          _selectedTargetSlot != null;
    }
    return false;
  }
}
