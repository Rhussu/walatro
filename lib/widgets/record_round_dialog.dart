import 'package:flutter/material.dart';
import 'package:walatro/models/table_score_model.dart';
import 'package:walatro/widgets/retro_ui.dart';

/// Diálogo para registrar o editar las puntuaciones de una ronda en el Anotador de Mesa.
class RecordRoundDialog extends StatefulWidget {
  final int roundNumber;
  final List<TablePlayer> players;
  final TableRound? existingRound;
  final void Function(TableRound round) onSave;

  const RecordRoundDialog({
    super.key,
    required this.roundNumber,
    required this.players,
    this.existingRound,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required int roundNumber,
    required List<TablePlayer> players,
    TableRound? existingRound,
    required void Function(TableRound round) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecordRoundDialog(
        roundNumber: roundNumber,
        players: players,
        existingRound: existingRound,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RecordRoundDialog> createState() => _RecordRoundDialogState();
}

class _RecordRoundDialogState extends State<RecordRoundDialog> {
  late RoundEndType _selectedEndType;
  String? _selectedCallerId;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _selectedEndType = widget.existingRound?.endType ?? RoundEndType.calledLow;
    if (_selectedEndType == RoundEndType.normal) {
      _selectedEndType = RoundEndType.calledLow;
    }
    _selectedCallerId = widget.existingRound?.callerPlayerId ??
        (widget.players.isNotEmpty ? widget.players.first.id : null);

    for (final player in widget.players) {
      final initialVal = widget.existingRound?.scores[player.id]?.rawPoints ?? 0;
      _controllers[player.id] = TextEditingController(text: initialVal.toString());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, int> _getRawScores() {
    final Map<String, int> raw = {};
    for (final player in widget.players) {
      final text = _controllers[player.id]?.text.trim() ?? '0';
      raw[player.id] = int.tryParse(text) ?? 0;
    }
    return raw;
  }

  void _adjustScore(String playerId, int delta) {
    final controller = _controllers[playerId];
    if (controller != null) {
      final current = int.tryParse(controller.text) ?? 0;
      final updated = current + delta;
      controller.text = updated.toString();
      setState(() {});
    }
  }

  void _handleSave() {
    final rawScores = _getRawScores();
    final computedScores = TableScoreState.computeRoundScores(
      rawScores: rawScores,
      endType: _selectedEndType,
      callerPlayerId: _selectedEndType == RoundEndType.calledLow ? _selectedCallerId : null,
    );

    final round = TableRound(
      roundNumber: widget.roundNumber,
      endType: _selectedEndType,
      callerPlayerId: _selectedEndType == RoundEndType.calledLow ? _selectedCallerId : null,
      scores: computedScores,
    );

    widget.onSave(round);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rawScores = _getRawScores();
    final computedScores = TableScoreState.computeRoundScores(
      rawScores: rawScores,
      endType: _selectedEndType,
      callerPlayerId: _selectedEndType == RoundEndType.calledLow ? _selectedCallerId : null,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 660),
        child: RetroContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ENCABEZADO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RONDA ${widget.roundNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withAlpha(40),
                      border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'REGISTRO',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECCIÓN 1: MOTIVO DE FIN DE RONDA
                      _buildSectionHeader('1. MOTIVO DE FIN DE RONDA'),
                      const SizedBox(height: 8),
                      _buildEndTypeSelector(),

                      // SELECTOR DE QUIÉN CANTÓ
                      if (_selectedEndType == RoundEndType.calledLow) ...[
                        const SizedBox(height: 12),
                        _buildCallerSelector(),
                      ],

                      const SizedBox(height: 16),

                      // SECCIÓN 2: PUNTOS DE LAS CARTAS
                      _buildSectionHeader('2. PUNTOS DE CARTAS EN MANO'),
                      const SizedBox(height: 4),
                      const Text(
                        'Ingresa la suma de cartas de cada jugador. Los modificadores (+30, +100 o -10) se calculan automáticamente.',
                        style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Courier'),
                      ),
                      const SizedBox(height: 10),

                      ...widget.players.map((player) {
                        final raw = rawScores[player.id] ?? 0;
                        final score = computedScores[player.id];
                        final modifier = score?.modifier ?? 0;

                        return _buildPlayerInputRow(player, raw, modifier);
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BOTONES DE ACCIÓN INFERIORES
              Row(
                children: [
                  Expanded(
                    child: RetroButton(
                      color: Colors.grey.shade800,
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      text: 'CANCELAR',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RetroButton(
                      color: const Color(0xFF00C853), // Verde
                      onPressed: _handleSave,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      text: 'GUARDAR',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFDE59), // Amarillo arcade
        fontFamily: 'Courier',
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildEndTypeSelector() {
    return Column(
      children: [
        _buildOptionRadio(
          title: 'Canto: "Soy el que tiene menos"',
          subtitle: 'Acierto: -10 pts | Fallo/Empate: +30 pts',
          type: RoundEndType.calledLow,
        ),
        const SizedBox(height: 6),
        _buildOptionRadio(
          title: 'Se agotó el mazo de robo',
          subtitle: 'Penalización: +100 pts al de menor puntuación',
          type: RoundEndType.deckEmpty,
        ),
      ],
    );
  }

  Widget _buildOptionRadio({
    required String title,
    required String subtitle,
    required RoundEndType type,
  }) {
    final isSelected = _selectedEndType == type;

    return InkWell(
      onTap: () => setState(() => _selectedEndType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3F37C9).withAlpha(120) : Colors.black38,
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFDE59) : Colors.white38,
                      fontFamily: 'Courier',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿QUIÉN CANTÓ "SOY EL QUE TIENE MENOS"?',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.players.map((p) {
              final isCaller = _selectedCallerId == p.id;
              return ChoiceChip(
                label: Text(
                  p.name,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    color: isCaller ? Colors.black : Colors.white,
                  ),
                ),
                selected: isCaller,
                selectedColor: const Color(0xFF00F0FF),
                backgroundColor: const Color(0xFF2B2B2B),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCallerId = p.id);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInputRow(TablePlayer player, int raw, int modifier) {
    final isCaller = _selectedEndType == RoundEndType.calledLow && _selectedCallerId == player.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCaller ? const Color(0xFF00F0FF).withAlpha(25) : Colors.black26,
        border: Border.all(
          color: isCaller ? const Color(0xFF00F0FF) : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (isCaller) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'CANTANTE',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Courier',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // VISTA PREVIA DEL RESULTADO VISUAL: RAW + MODIFICADOR
              _buildResultPreview(raw, modifier),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Botón -5
              _buildQuickButton('-5', () => _adjustScore(player.id, -5)),
              const SizedBox(width: 4),
              // Botón -1
              _buildQuickButton('-1', () => _adjustScore(player.id, -1)),
              const SizedBox(width: 8),
              // Input numérico
              Expanded(
                child: TextField(
                  controller: _controllers[player.id],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    filled: true,
                    fillColor: Color(0xFF1E1E24),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // Botón +1
              _buildQuickButton('+1', () => _adjustScore(player.id, 1)),
              const SizedBox(width: 4),
              // Botón +5
              _buildQuickButton('+5', () => _adjustScore(player.id, 5)),
              const SizedBox(width: 4),
              // Botón +10
              _buildQuickButton('+10', () => _adjustScore(player.id, 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B2B2B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(36, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.white30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultPreview(int raw, int modifier) {
    if (modifier == 0) {
      return Text(
        '$raw pts',
        style: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    final isPositiveMod = modifier > 0;
    final modText = isPositiveMod ? '+$modifier' : '$modifier';
    final modColor = isPositiveMod ? const Color(0xFFFF5252) : const Color(0xFF00E676);
    final total = raw + modifier;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$raw ',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: modColor.withAlpha(40),
            border: Border.all(color: modColor, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            modText,
            style: TextStyle(
              color: modColor,
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          ' = $total pts',
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
