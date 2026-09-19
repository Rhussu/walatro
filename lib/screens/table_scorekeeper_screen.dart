import 'package:flutter/material.dart';
import 'package:walatro/models/table_score_model.dart';
import 'package:walatro/services/table_score_storage.dart';
import 'package:walatro/widgets/hypnotic_background.dart';
import 'package:walatro/widgets/record_round_dialog.dart';
import 'package:walatro/widgets/retro_ui.dart';
import 'package:walatro/widgets/rules_dialog.dart';

class TableScorekeeperScreen extends StatefulWidget {
  const TableScorekeeperScreen({super.key});

  @override
  State<TableScorekeeperScreen> createState() => _TableScorekeeperScreenState();
}

class _TableScorekeeperScreenState extends State<TableScorekeeperScreen> {
  TableScoreState _state = TableScoreState.createDefault();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final loaded = await TableScoreStorage.loadState();
    if (mounted) {
      setState(() {
        _state = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveState(TableScoreState newState) async {
    setState(() => _state = newState);
    await TableScoreStorage.saveState(newState);
  }

  void _addPlayer() {
    final textController = TextEditingController(
      text: 'JUGADOR ${_state.players.length + 1}',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: RetroContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'NUEVO JUGADOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Color(0xFFFFDE59)),
                    filled: true,
                    fillColor: Color(0xFF1E1E24),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        color: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'CANCELAR',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RetroButton(
                        color: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'AGREGAR',
                        onPressed: () {
                          final name = textController.text.trim();
                          if (name.isNotEmpty) {
                            final newPlayer = TablePlayer(
                              id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                              name: name.toUpperCase(),
                            );
                            _saveState(_state.copyWith(
                              players: [..._state.players, newPlayer],
                            ));
                          }
                          Navigator.of(ctx).pop();
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

  void _removePlayer(TablePlayer player) {
    if (_state.players.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requieren al menos 2 jugadores.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: RetroContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿ELIMINAR A ${player.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Se eliminarán sus registros de puntos de esta partida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Courier'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        color: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'CANCELAR',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RetroButton(
                        color: const Color(0xFFD90429),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'ELIMINAR',
                        onPressed: () {
                          final updatedPlayers = _state.players.where((p) => p.id != player.id).toList();
                          _saveState(_state.copyWith(players: updatedPlayers));
                          Navigator.of(ctx).pop();
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

  void _adjustTargetRounds(int delta) {
    final next = (_state.targetRounds + delta).clamp(1, 30);
    _saveState(_state.copyWith(targetRounds: next));
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: RetroContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿REINICIAR PARTIDA?',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Se borrarán todas las rondas anotadas para empezar una nueva partida de mesa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Courier'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        color: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'NO, VOLVER',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RetroButton(
                        color: const Color(0xFFD90429),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'SÍ, REINICIAR',
                        onPressed: () {
                          final reset = TableScoreState(
                            players: _state.players,
                            targetRounds: _state.targetRounds,
                            rounds: const [],
                          );
                          _saveState(reset);
                          Navigator.of(ctx).pop();
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

  void _recordNewRound() {
    final nextRoundNumber = _state.rounds.length + 1;
    RecordRoundDialog.show(
      context: context,
      roundNumber: nextRoundNumber,
      players: _state.players,
      onSave: (round) {
        final updatedRounds = [..._state.rounds, round];
        _saveState(_state.copyWith(rounds: updatedRounds));

        if (updatedRounds.length == _state.targetRounds) {
          _showGameOverCelebration();
        }
      },
    );
  }

  void _editRound(TableRound round) {
    RecordRoundDialog.show(
      context: context,
      roundNumber: round.roundNumber,
      players: _state.players,
      existingRound: round,
      onSave: (updatedRound) {
        final updatedList = _state.rounds.map((r) {
          return r.roundNumber == updatedRound.roundNumber ? updatedRound : r;
        }).toList();
        _saveState(_state.copyWith(rounds: updatedList));
      },
    );
  }

  void _deleteRound(int roundNumber) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: RetroContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿ELIMINAR RONDA $roundNumber?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: RetroButton(
                        color: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'CANCELAR',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RetroButton(
                        color: const Color(0xFFD90429),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        text: 'ELIMINAR',
                        onPressed: () {
                          final updatedList = _state.rounds.where((r) => r.roundNumber != roundNumber).toList();
                          // Renumerar rondas posteriores
                          final renumbered = <TableRound>[];
                          for (int i = 0; i < updatedList.length; i++) {
                            final r = updatedList[i];
                            renumbered.add(TableRound(
                              roundNumber: i + 1,
                              endType: r.endType,
                              callerPlayerId: r.callerPlayerId,
                              scores: r.scores,
                            ));
                          }
                          _saveState(_state.copyWith(rounds: renumbered));
                          Navigator.of(ctx).pop();
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

  void _showGameOverCelebration() {
    final leaderIds = _state.getLeadingPlayerIds();
    final winners = _state.players.where((p) => leaderIds.contains(p.id)).toList();
    final winnerNames = winners.map((w) => w.name).join(' & ');
    final minScore = winners.isNotEmpty ? _state.totalScoreForPlayer(winners.first.id) : 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: RetroContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '👑 ¡PARTIDA COMPLETADA! 👑',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFDE59),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'GANADOR:\n$winnerNames',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Puntuación final: $minScore pts',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                RetroButton(
                  color: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  text: 'ACEPTAR',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1423),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
      );
    }

    final leaderIds = _state.getLeadingPlayerIds();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF00F0FF), size: 26),
            SizedBox(width: 8),
            Text(
              'ANOTADOR DE MESA',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reglas de puntuación',
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFFFFDE59)),
            onPressed: () => RulesDialog.show(context),
          ),
          IconButton(
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFFF5252)),
            onPressed: _resetGame,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: HypnoticBackground(
        child: SafeArea(
          child: Column(
            children: [
              // BARRA SUPERIOR DE CONTROLES: RONDAS Y JUGADORES
              _buildConfigBar(),

              // TABLA DE PUNTUACIONES
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildScoreTable(leaderIds),
                ),
              ),

              // BOTÓN INFERIOR DE ACCIÓN RÁPIDA: ANOTAR SIGUIENTE RONDA
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de controles superior con selector de rondas y botón de agregar jugador
  Widget _buildConfigBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24).withAlpha(230),
        border: Border.all(color: Colors.white30, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Selector de Rondas
          Row(
            children: [
              const Text(
                'RONDAS: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFFDE59), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _adjustTargetRounds(-1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_state.targetRounds}',
                  style: const TextStyle(
                    color: Color(0xFFFFDE59),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFDE59), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _adjustTargetRounds(1),
              ),
            ],
          ),

          // Botón Agregar Jugador
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text(
              '+ JUGADOR',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            onPressed: _addPlayer,
          ),
        ],
      ),
    );
  }

  /// Tabla completa con desplazamiento horizontal y vertical
  Widget _buildScoreTable(List<String> leaderIds) {
    final roundCount = _state.targetRounds > _state.rounds.length
        ? _state.targetRounds
        : _state.rounds.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181920).withAlpha(235),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2B2B36)),
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              columnSpacing: 20,
              horizontalMargin: 12,
              border: TableBorder.all(color: Colors.white24, width: 1),
              columns: [
                // Columna 1: Ronda
                const DataColumn(
                  label: Text(
                    'RONDA',
                    style: TextStyle(
                      color: Color(0xFFFFDE59),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                // Columnas de jugadores
                ..._state.players.map((player) {
                  final isLeader = leaderIds.contains(player.id);
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLeader && _state.rounds.isNotEmpty) ...[
                          const Text('👑 ', style: TextStyle(fontSize: 14)),
                        ],
                        Text(
                          player.name,
                          style: TextStyle(
                            color: isLeader ? const Color(0xFFFFDE59) : Colors.white,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removePlayer(player),
                          child: const Icon(Icons.close, size: 14, color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }),

                // Columna de Acciones
                const DataColumn(
                  label: Text(
                    'DETALLE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],

              rows: [
                // Filas por ronda
                ...List.generate(roundCount, (index) {
                  final roundNum = index + 1;
                  final hasScore = index < _state.rounds.length;
                  final round = hasScore ? _state.rounds[index] : null;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (index % 2 == 1) return Colors.black12;
                      return Colors.transparent;
                    }),
                    cells: [
                      // Celda de Ronda
                      DataCell(
                        Text(
                          'R$roundNum',
                          style: TextStyle(
                            color: hasScore ? const Color(0xFF00F0FF) : Colors.white38,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Celdas de jugadores con formato "raw +modificador"
                      ..._state.players.map((player) {
                        if (!hasScore) {
                          return const DataCell(
                            Text(
                              '-',
                              style: TextStyle(color: Colors.white24, fontFamily: 'Courier'),
                            ),
                          );
                        }

                        final score = round!.scores[player.id];
                        if (score == null) {
                          return const DataCell(
                            Text('-', style: TextStyle(color: Colors.white24)),
                          );
                        }

                        return DataCell(_buildScoreCellContent(score));
                      }),

                      // Celda de detalle y opciones
                      DataCell(
                        hasScore
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildEndTypeBadge(round!.endType),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Color(0xFF00F0FF)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _editRound(round),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFFF5252)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteRound(round.roundNumber),
                                  ),
                                ],
                              )
                            : (index == _state.rounds.length
                                ? InkWell(
                                    onTap: _recordNewRound,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 16, color: Color(0xFF00E676)),
                                        SizedBox(width: 2),
                                        Text(
                                          'ANOTAR',
                                          style: TextStyle(
                                            color: Color(0xFF00E676),
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Text(
                                    'Pendiente',
                                    style: TextStyle(
                                      color: Colors.white24,
                                      fontFamily: 'Courier',
                                      fontSize: 11,
                                    ),
                                  )),
                      ),
                    ],
                  );
                }),

                // FILA FINAL: TOTALES ACUMULADOS
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF222430)),
                  cells: [
                    const DataCell(
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Color(0xFFFFDE59),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ..._state.players.map((player) {
                      final total = _state.totalScoreForPlayer(player.id);
                      final isLeader = leaderIds.contains(player.id);

                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: isLeader && _state.rounds.isNotEmpty
                              ? BoxDecoration(
                                  color: const Color(0xFFFFDE59).withAlpha(35),
                                  border: Border.all(color: const Color(0xFFFFDE59), width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: Text(
                            '$total pts',
                            style: TextStyle(
                              color: isLeader && _state.rounds.isNotEmpty
                                  ? const Color(0xFFFFDE59)
                                  : Colors.white,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        '${_state.rounds.length}/${_state.targetRounds}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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

  /// Visualización en la celda con desglose: rawPoints + modificador en color diferenciado
  Widget _buildScoreCellContent(PlayerRoundScore score) {
    if (score.modifier == 0) {
      return Text(
        '${score.rawPoints}',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    final isPositive = score.modifier > 0;
    final modText = isPositive ? '+${score.modifier}' : '${score.modifier}';
    // Color diferenciado para los modificadores
    final modColor = isPositive ? const Color(0xFFFF5252) : const Color(0xFF00E676);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${score.rawPoints} ',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: modColor.withAlpha(45),
            border: Border.all(color: modColor, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            modText,
            style: TextStyle(
              color: modColor,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndTypeBadge(RoundEndType endType) {
    String label = 'NORMAL';
    Color color = Colors.white54;

    switch (endType) {
      case RoundEndType.calledLow:
      case RoundEndType.zeroCards:
        label = 'LLAMADO';
        color = const Color(0xFF00F0FF);
        break;
      case RoundEndType.deckEmpty:
        label = 'MAZO 0';
        color = const Color(0xFFFF5252);
        break;
      case RoundEndType.normal:
        label = 'NORMAL';
        color = Colors.white54;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Botón inferior para anotar la siguiente ronda
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: RetroButton(
        color: const Color(0xFF00C853),
        onPressed: _recordNewRound,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'ANOTAR RONDA ${_state.rounds.length + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
