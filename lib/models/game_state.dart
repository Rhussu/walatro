import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/player_game_state.dart';

enum GamePhase {
  waiting,
  initialPeek, // Los 5 seg para memorizar las 2 cartas inferiores
  playerTurn, // Esperando que el jugador activo cante menor o robe carta
  cardDrawn, // Carta robada en mano, decidir cambiar o descartar
  powerChoice, // 7, 8 o 9 descartado: opción de usar poder o saltar
  roundEnd, // Fin de ronda: revelar cartas y calcular puntajes
}

class GameState {
  final int roundNumber;
  final GamePhase phase;
  final String? activePlayerName;
  final int drawPileCount;
  final List<CardModel> discardPile;
  final List<PlayerGameState> players;
  final CardModel? drawnCard;
  final String? drawnFrom; // 'deck' | 'discard'
  final CardModel? pendingPowerCard; // 7, 8 o 9 esperando decisión
  final CardModel? revealedCardForPeek; // Carta mostrada por poder 7 o 8
  final String? revealedCardOwner;
  final int? revealedCardSlot;
  final CardModel? burnedCard; // Carta recién quemada (efecto fuego)
  final CardModel? powerActivatedCard; // Carta con poder activo (aura brillante)
  final int? selectedMyPowerSlot; // Slot propio seleccionado para intercambio (Poder 9)
  final String? lastEventMessage;
  final String? roundEndReason;
  final String? roundEndCaller;

  GameState({
    this.roundNumber = 1,
    this.phase = GamePhase.waiting,
    this.activePlayerName,
    this.drawPileCount = 0,
    List<CardModel>? discardPile,
    List<PlayerGameState>? players,
    this.drawnCard,
    this.drawnFrom,
    this.pendingPowerCard,
    this.revealedCardForPeek,
    this.revealedCardOwner,
    this.revealedCardSlot,
    this.burnedCard,
    this.powerActivatedCard,
    this.selectedMyPowerSlot,
    this.lastEventMessage,
    this.roundEndReason,
    this.roundEndCaller,
  })  : discardPile = discardPile ?? [],
        players = players ?? [];

  CardModel? get topDiscard => discardPile.isNotEmpty ? discardPile.last : null;

  /// Carta expuesta inmediatamente debajo de la cima del descarte
  CardModel? get underlyingDiscard =>
      discardPile.length > 1 ? discardPile[discardPile.length - 2] : null;

  /// ¿La carta superior del descarte se puede robar?
  /// Regla: solo si NO fue quemada por paridad
  bool get canDrawFromDiscard {
    if (topDiscard == null) return false;
    return topDiscard!.canPickFromDiscard;
  }

  PlayerGameState? getPlayer(String name) {
    try {
      return players.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  GameState copyWith({
    int? roundNumber,
    GamePhase? phase,
    String? activePlayerName,
    int? drawPileCount,
    List<CardModel>? discardPile,
    List<PlayerGameState>? players,
    CardModel? drawnCard,
    bool clearDrawnCard = false,
    String? drawnFrom,
    CardModel? pendingPowerCard,
    bool clearPendingPower = false,
    CardModel? revealedCardForPeek,
    bool clearRevealedPeek = false,
    String? revealedCardOwner,
    int? revealedCardSlot,
    CardModel? burnedCard,
    bool clearBurnedCard = false,
    CardModel? powerActivatedCard,
    bool clearPowerActivated = false,
    int? selectedMyPowerSlot,
    bool clearSelectedMyPowerSlot = false,
    String? lastEventMessage,
    String? roundEndReason,
    String? roundEndCaller,
  }) {
    return GameState(
      roundNumber: roundNumber ?? this.roundNumber,
      phase: phase ?? this.phase,
      activePlayerName: activePlayerName ?? this.activePlayerName,
      drawPileCount: drawPileCount ?? this.drawPileCount,
      discardPile: discardPile ?? List<CardModel>.from(this.discardPile),
      players: players ?? List<PlayerGameState>.from(this.players),
      drawnCard: clearDrawnCard ? null : (drawnCard ?? this.drawnCard),
      drawnFrom: clearDrawnCard ? null : (drawnFrom ?? this.drawnFrom),
      pendingPowerCard: clearPendingPower ? null : (pendingPowerCard ?? this.pendingPowerCard),
      revealedCardForPeek: clearRevealedPeek ? null : (revealedCardForPeek ?? this.revealedCardForPeek),
      revealedCardOwner: clearRevealedPeek ? null : (revealedCardOwner ?? this.revealedCardOwner),
      revealedCardSlot: clearRevealedPeek ? null : (revealedCardSlot ?? this.revealedCardSlot),
      burnedCard: clearBurnedCard ? null : (burnedCard ?? this.burnedCard),
      powerActivatedCard: clearPowerActivated ? null : (powerActivatedCard ?? this.powerActivatedCard),
      selectedMyPowerSlot: clearSelectedMyPowerSlot
          ? null
          : (selectedMyPowerSlot ?? this.selectedMyPowerSlot),
      lastEventMessage: lastEventMessage ?? this.lastEventMessage,
      roundEndReason: roundEndReason ?? this.roundEndReason,
      roundEndCaller: roundEndCaller ?? this.roundEndCaller,
    );
  }
}
