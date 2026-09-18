import 'package:flutter/material.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/services/game_controller.dart';
import 'package:walatro/services/room_services.dart';
import 'package:walatro/widgets/center_table_widget.dart';
import 'package:walatro/widgets/player_board_widget.dart';
import 'package:walatro/widgets/power_action_dialog.dart';
import 'package:walatro/widgets/round_summary_dialog.dart';
import 'package:walatro/widgets/rules_dialog.dart';

class GameScreen extends StatefulWidget {
  final RoomService? roomService;
  final String? myName;

  const GameScreen({super.key, this.roomService, this.myName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  int? _selectedSwapSlot;

  @override
  void initState() {
    super.initState();
    final name = widget.myName ?? widget.roomService?.myName ?? 'PLAYER_1';
    _controller = GameController(
      roomService: widget.roomService,
      myPlayerName: name,
    );

    // Si entramos sin backend o en sala local, iniciamos simulación de prueba
    if (widget.roomService == null || widget.roomService?.currentRoom == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.startSimulatedGame();
      });
    } else {
      // Si entramos con backend, solicitamos sync si aún no tenemos jugadores cargados
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.state.players.isEmpty) {
          widget.roomService?.requestGameSync();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCardTap(String owner, int slotIndex) {
    // 1. Si el botón de paridad está armado: ejecutar intento de paridad
    if (_controller.isParityArmed) {
      _controller.claimParity(owner, slotIndex);
      return;
    }

    // 2. Si el jugador robó y está seleccionando qué carta cambiar
    if (_controller.isMyTurn &&
        _controller.state.phase == GamePhase.cardDrawn &&
        owner == _controller.myPlayerName) {
      _controller.swapDrawnCard(slotIndex);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final myPlayer = _controller.myPlayer;
        final opponents = state.players.where((p) => p.name != _controller.myPlayerName).toList();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Text(
                  'RONDA ${state.roundNumber}',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.roomService?.currentRoom != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SALA: ${widget.roomService!.currentRoom}',
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MODO PRÁCTICA',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                  ),
              ],
            ),
            actions: [
              // Botón permanente para consultar las Reglas
              TextButton.icon(
                icon: const Icon(Icons.menu_book, color: Colors.amberAccent, size: 20),
                label: const Text(
                  'REGLAS',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => RulesDialog.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Fondo de mesa de cartas / retro
              Positioned.fill(
                child: Image.asset(
                  'assets/images/fondo.jpg',
                  fit: BoxFit.cover,
                  color: Colors.black.withAlpha(160),
                  colorBlendMode: BlendMode.darken,
                ),
              ),

              // Área de juego responsiva
              SafeArea(
                child: Column(
                  children: [
                    // Banner de estado y mensajes de eventos
                    _buildStatusBar(state),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            // 1. Tableros de los rivales (arriba)
                            if (opponents.isNotEmpty) ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var op in opponents) ...[
                                      PlayerBoardWidget(
                                        player: op,
                                        isLocalPlayer: false,
                                        isActiveTurn: state.activePlayerName == op.name,
                                        isParityArmed: _controller.isParityArmed,
                                        cardWidth: 54,
                                        cardHeight: 76,
                                        onCardTapped: (slot) => _handleCardTap(op.name, slot),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // 2. Zona central (Mazo de robo, Descarte, Paridad)
                            CenterTableWidget(
                              gameState: state,
                              isMyTurn: _controller.isMyTurn,
                              isParityArmed: _controller.isParityArmed,
                              selectedSlotToSwap: _selectedSwapSlot,
                              onDrawDeck: () => _controller.drawCard('deck'),
                              onDrawDiscard: () => _controller.drawCard('discard'),
                              onToggleParity: () => _controller.toggleParityArm(),
                              onDiscardDrawn: () => _controller.discardDrawnCard(),
                              onCallLowest: () => _controller.callLowest(),
                            ),
                            const SizedBox(height: 14),

                            // 3. Tablero del jugador local (abajo)
                            if (myPlayer != null)
                              PlayerBoardWidget(
                                player: myPlayer,
                                isLocalPlayer: true,
                                isActiveTurn: _controller.isMyTurn,
                                isParityArmed: _controller.isParityArmed,
                                cardWidth: 70,
                                cardHeight: 100,
                                onCardTapped: (slot) => _handleCardTap(_controller.myPlayerName, slot),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Modal flotante de selección de poder (7, 8 o 9)
              if (state.phase == GamePhase.powerChoice && state.pendingPowerCard != null)
                PowerActionDialog(
                  powerCard: state.pendingPowerCard!,
                  gameState: state,
                  myPlayerName: _controller.myPlayerName,
                  onUsePower: (type, {mySlot, targetPlayer, targetSlot}) {
                    _controller.usePower(
                      type,
                      mySlot: mySlot,
                      targetPlayer: targetPlayer,
                      targetSlot: targetSlot,
                    );
                  },
                  onSkipPower: () => _controller.skipPower(),
                ),

              // Modal de fin de ronda y puntuaciones
              if (state.phase == GamePhase.roundEnd)
                RoundSummaryDialog(
                  gameState: state,
                  myPlayerName: _controller.myPlayerName,
                  onNextRound: () => _controller.requestNextRound(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(GameState state) {
    if (state.phase == GamePhase.initialPeek) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.deepPurple.shade900,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'MEMORIZA TUS 2 CARTAS INFERIORES: ${_controller.peekCountdown}s',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }


    if (state.lastEventMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: Colors.black87,
        child: Text(
          state.lastEventMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}