import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/game_config.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/models/player_game_state.dart';
import 'package:walatro/services/room_services.dart';

class GameController extends ChangeNotifier {
  final RoomService? roomService;
  final String myPlayerName;
  GameConfig config;

  GameState _state = GameState();
  GameState get state => _state;

  bool _isParityArmed = false;
  bool get isParityArmed => _isParityArmed;

  int _peekCountdown = 0;
  int get peekCountdown => _peekCountdown;

  Timer? _peekTimer;
  Timer? _effectTimer;

  bool get isMyTurn => _state.activePlayerName == myPlayerName;
  PlayerGameState? get myPlayer => _state.getPlayer(myPlayerName);

  GameController({
    this.roomService,
    required this.myPlayerName,
    this.config = const GameConfig(),
  }) {
    if (roomService != null) {
      _bindSocketEvents();
    }
  }

  void _bindSocketEvents() {
    roomService?.onRoundStarted = (data) => _handleSocketRoundStarted(data);
    roomService?.onTurnChanged = (player) => _handleSocketTurnChanged(player);
    roomService?.onCardDrawn = (data) => _handleSocketCardDrawn(data);
    roomService?.onCardDiscarded = (data) => _handleSocketCardDiscarded(data);
    roomService?.onCardBurned = (data) => _handleSocketCardBurned(data);
    roomService?.onPowerActivated = (data) => _handleSocketPowerActivated(data);
    roomService?.onParityResolved = (data) => _handleSocketParityResolved(data);
    roomService?.onPrivatePeek = (data) => _handleSocketPrivatePeek(data);
    roomService?.onRoundEnded = (data) => _handleSocketRoundEnded(data);
    roomService?.onHandUpdated = (data) => _handleSocketHandUpdated(data);
    roomService?.onPlayerCountsUpdated = (data) => _handleSocketPlayerCountsUpdated(data);
  }

  // ==========================================
  // MANEJO DE EVENTOS DEL SOCKET (BACKEND)
  // ==========================================

  void _handleSocketRoundStarted(Map<String, dynamic> data) {
    var rawHand = data['myHand'] as List?;
    List<CardModel?> myCards = [];
    if (rawHand != null) {
      myCards = rawHand.map((c) => c != null ? CardModel.fromJson(c) : null).toList();
    }

    var othersRaw = data['otherPlayers'] as List? ?? [];
    List<PlayerGameState> players = [
      PlayerGameState(name: myPlayerName, cards: myCards),
    ];

    for (var o in othersRaw) {
      int count = o['cardCount'] ?? 4;
      players.add(PlayerGameState(
        name: o['name'],
        cards: List.generate(count, (i) => CardModel(
          id: '${o['name']}_$i',
          suit: CardSuit.spades,
          rank: CardRank.ace,
          isFaceUp: false,
        )),
      ));
    }

    CardModel? topDiscard;
    if (data['topDiscard'] != null) {
      topDiscard = CardModel.fromJson(data['topDiscard']);
    }

    _state = _state.copyWith(
      roundNumber: data['roundNumber'] ?? 1,
      phase: GamePhase.initialPeek,
      players: players,
      drawPileCount: data['deckCount'] ?? 40,
      discardPile: topDiscard != null ? [topDiscard] : [],
      lastEventMessage: '¡Comienza la ronda! Memoriza tus 2 cartas inferiores.',
    );

    _startPeekCountdown(data['peekDurationSeconds'] ?? config.peekDurationSeconds);
    notifyListeners();
  }

  void _handleSocketTurnChanged(String player) {
    _state = _state.copyWith(
      activePlayerName: player,
      phase: GamePhase.playerTurn,
      clearDrawnCard: true,
      clearPendingPower: true,
      lastEventMessage: player == myPlayerName ? '¡Es tu turno!' : 'Turno de $player',
    );
    notifyListeners();
  }

  void _handleSocketCardDrawn(Map<String, dynamic> data) {
    String player = data['playerName'];
    CardModel? card;
    if (data['card'] != null) {
      card = CardModel.fromJson(data['card'])..isFaceUp = true;
    }

    _state = _state.copyWith(
      phase: GamePhase.cardDrawn,
      drawnCard: card,
      drawnFrom: data['from'],
      drawPileCount: data['from'] == 'deck' ? max(0, _state.drawPileCount - 1) : _state.drawPileCount,
      lastEventMessage: '$player robó del ${data['from'] == 'deck' ? 'mazo' : 'descarte'}.',
    );
    notifyListeners();
  }

  void _handleSocketCardDiscarded(Map<String, dynamic> data) {
    CardModel discarded = CardModel.fromJson(data['card'])..isFaceUp = true;
    List<CardModel> newDiscard = List.from(_state.discardPile)..add(discarded);

    bool powerAvailable = data['powerAvailable'] ?? false;
    String player = data['playerName'];

    _state = _state.copyWith(
      discardPile: newDiscard,
      phase: (player == myPlayerName && powerAvailable && discarded.canTriggerPower)
          ? GamePhase.powerChoice
          : GamePhase.playerTurn,
      pendingPowerCard: (player == myPlayerName && powerAvailable && discarded.canTriggerPower)
          ? discarded
          : null,
      clearDrawnCard: true,
      lastEventMessage: '$player descartó un ${discarded.rankLabel}${discarded.suitSymbol}.',
    );
    notifyListeners();
  }

  void _handleSocketCardBurned(Map<String, dynamic> data) {
    CardModel burned = CardModel.fromJson(data['card'])..isBurned = true;
    String by = data['burnedBy'];

    _triggerBurnEffect(burned);
    _state = _state.copyWith(
      lastEventMessage: '🔥 ¡Carta quemada por paridad por $by! 🔥',
    );
    notifyListeners();
  }

  void _handleSocketPowerActivated(Map<String, dynamic> data) {
    CardModel card = CardModel.fromJson(data['card'])..powerUsed = true;
    String user = data['user'];

    _triggerPowerEffect(card);
    _state = _state.copyWith(
      lastEventMessage: '✨ $user activó el poder especial de ${card.rankLabel}! ✨',
    );
    notifyListeners();
  }

  void _handleSocketParityResolved(Map<String, dynamic> data) {
    _isParityArmed = false;
    String caller = data['caller'] ?? '';
    String targetPlayer = data['targetPlayer'] ?? caller;
    int slotIndex = data['slotIndex'] ?? 0;
    bool success = data['success'] ?? false;
    CardModel cardPlayed = CardModel.fromJson(data['cardPlayed']);

    var target = _state.getPlayer(targetPlayer);
    var callerP = _state.getPlayer(caller);

    if (success) {
      _triggerBurnEffect(cardPlayed);
      if (caller == targetPlayer) {
        if (target != null && slotIndex >= 0 && slotIndex < target.cards.length) {
          target.cards[slotIndex] = null;
        }
      } else {
        if (target != null && slotIndex >= 0 && slotIndex < target.cards.length) {
          target.cards[slotIndex] = null;
        }
        if (callerP != null) {
          int myIdx = callerP.cards.indexWhere((c) => c != null);
          if (myIdx != -1 && target != null) {
            var givenCard = callerP.cards[myIdx];
            callerP.cards[myIdx] = null;
            target.cards[slotIndex] = givenCard;
          }
        }
      }
      _state = _state.copyWith(
        lastEventMessage: '🎯 ¡Paridad EXITOSA de $caller!',
      );
    } else {
      if (caller == targetPlayer) {
        CardModel penalty = (data['penaltyCard'] != null)
            ? CardModel.fromJson(data['penaltyCard'])
            : CardModel(id: 'pen_${DateTime.now().millisecondsSinceEpoch}', suit: CardSuit.spades, rank: CardRank.ace, isFaceUp: false);
        penalty.isFaceUp = false;
        callerP?.cards.add(penalty);
      } else {
        if (target != null && slotIndex >= 0 && slotIndex < target.cards.length) {
          target.cards[slotIndex] = null;
        }
        cardPlayed.isFaceUp = false;
        callerP?.cards.add(cardPlayed);
        CardModel penalty = (data['penaltyCard'] != null)
            ? CardModel.fromJson(data['penaltyCard'])
            : CardModel(id: 'pen_${DateTime.now().millisecondsSinceEpoch}', suit: CardSuit.spades, rank: CardRank.ace, isFaceUp: false);
        penalty.isFaceUp = false;
        callerP?.cards.add(penalty);
      }
      _state = _state.copyWith(
        lastEventMessage: '❌ ¡Paridad FALLIDA de $caller!',
      );
    }
    notifyListeners();
  }

  void _handleSocketPrivatePeek(Map<String, dynamic> data) {
    CardModel card = CardModel.fromJson(data['card'])..isFaceUp = true;
    String targetPlayer = data['targetPlayer'];
    int slotIndex = data['slotIndex'];

    var target = _state.getPlayer(targetPlayer);
    if (target != null && slotIndex >= 0 && slotIndex < target.cards.length) {
      target.cards[slotIndex] = card;
      notifyListeners();

      Timer(const Duration(milliseconds: 3500), () {
        if (slotIndex < target.cards.length && target.cards[slotIndex] != null) {
          target.cards[slotIndex]!.isFaceUp = false;
          notifyListeners();
        }
      });
    }
  }

  void _handleSocketRoundEnded(Map<String, dynamic> data) {
    List<PlayerGameState> updatedPlayers = [];
    if (data['players'] != null) {
      for (var pJson in (data['players'] as List)) {
        var rawCards = pJson['cards'] as List? ?? [];
        List<CardModel?> pCards = rawCards.map((c) => c != null ? (CardModel.fromJson(c)..isFaceUp = true) : null).toList();
        updatedPlayers.add(PlayerGameState(
          name: pJson['name'] ?? '',
          cards: pCards,
          roundScore: pJson['roundScore'] ?? 0,
          totalScore: pJson['totalScore'] ?? 0,
        ));
      }
    } else {
      updatedPlayers = _state.players;
    }

    _state = _state.copyWith(
      players: updatedPlayers,
      phase: GamePhase.roundEnd,
      roundEndReason: data['reason'],
      roundEndCaller: data['caller'],
      lastEventMessage: '¡Fin de la ronda! Se cuentan los puntos.',
    );
    notifyListeners();
  }

  void _handleSocketHandUpdated(Map<String, dynamic> data) {
    if (data['myHand'] != null) {
      var raw = data['myHand'] as List;
      List<CardModel?> myCards = raw.map((c) => c != null ? CardModel.fromJson(c) : null).toList();
      var me = myPlayer;
      if (me != null) {
        me.cards = myCards;
        notifyListeners();
      }
    }
  }

  void _handleSocketPlayerCountsUpdated(Map<String, dynamic> data) {
    if (data['players'] != null) {
      for (var pInfo in (data['players'] as List)) {
        String pName = pInfo['name'];
        if (pName != myPlayerName) {
          var p = _state.getPlayer(pName);
          if (p != null) {
            int count = pInfo['cardCount'] ?? 4;
            int currentActive = p.cards.where((c) => c != null).length;
            if (currentActive != count) {
              p.cards = List.generate(count, (i) => CardModel(
                id: '${pName}_$i',
                suit: CardSuit.spades,
                rank: CardRank.ace,
                isFaceUp: false,
              ));
            }
          }
        }
      }
      notifyListeners();
    }
  }

  // ==========================================
  // ACCIONES DEL JUGADOR
  // ==========================================

  /// Activa o desactiva el botón de Paridad local
  void toggleParityArm() {
    _isParityArmed = !_isParityArmed;
    notifyListeners();
  }

  /// Cantar "Soy el que tiene menos cartas" (antes de robar)
  void callLowest() {
    if (!isMyTurn || _state.phase != GamePhase.playerTurn) return;

    if (roomService != null) {
      roomService!.callLowest();
    } else {
      _simCallLowest(myPlayerName);
    }
  }

  /// Robar carta: 'deck' o 'discard'
  void drawCard(String from) {
    if (!isMyTurn || _state.phase != GamePhase.playerTurn) return;

    if (from == 'discard' && !_state.canDrawFromDiscard) {
      _state = _state.copyWith(
        lastEventMessage: 'No puedes robar del descarte: la carta fue quemada en paridad.',
      );
      notifyListeners();
      return;
    }

    if (roomService != null) {
      roomService!.drawCard(from);
    } else {
      _simDrawCard(from);
    }
  }

  /// Cambiar carta robada por una de su mano
  void swapDrawnCard(int slotIndex) {
    if (!isMyTurn || _state.phase != GamePhase.cardDrawn) return;

    if (roomService != null) {
      roomService!.playDrawnCard('SWAP', slotIndex);
    } else {
      _simSwapDrawnCard(slotIndex);
    }
  }

  /// Descartar la carta robada directamente
  void discardDrawnCard() {
    if (!isMyTurn || _state.phase != GamePhase.cardDrawn) return;

    if (roomService != null) {
      roomService!.playDrawnCard('DISCARD', null);
    } else {
      _simDiscardDrawnCard();
    }
  }

  /// Usar poder de 7, 8 o 9
  void usePower(String powerType, {int? mySlot, String? targetPlayer, int? targetSlot}) {
    if (roomService != null) {
      roomService!.usePower(powerType, mySlot: mySlot, targetPlayer: targetPlayer, targetSlot: targetSlot);
    } else {
      _simUsePower(powerType, mySlot: mySlot, targetPlayer: targetPlayer, targetSlot: targetSlot);
    }
  }

  /// Saltar / No usar poder
  void skipPower() {
    if (roomService != null) {
      roomService!.skipPower();
    } else {
      _state = _state.copyWith(
        clearPendingPower: true,
        phase: GamePhase.playerTurn,
        lastEventMessage: 'Poder omitido.',
      );
      _advanceSimTurn();
      notifyListeners();
    }
  }

  /// Cantar paridad sobre una carta (propia o ajena)
  void claimParity(String targetPlayer, int slotIndex) {
    if (!_isParityArmed) return;
    _isParityArmed = false; // Desarma el botón local

    if (_state.topDiscard == null) {
      notifyListeners();
      return;
    }

    if (roomService != null) {
      roomService!.claimParity(targetPlayer, slotIndex);
    } else {
      _simClaimParity(targetPlayer, slotIndex);
    }
    notifyListeners();
  }

  void requestNextRound() {
    if (roomService != null) {
      roomService!.requestNextRound();
    } else {
      _state = _state.copyWith(roundNumber: _state.roundNumber + 1);
      startSimulatedGame();
    }
  }

  void _triggerBurnEffect(CardModel card) {
    _state = _state.copyWith(burnedCard: card);
    notifyListeners();

    _effectTimer?.cancel();
    _effectTimer = Timer(const Duration(milliseconds: 1800), () {
      _state = _state.copyWith(clearBurnedCard: true);
      notifyListeners();
    });
  }

  void _triggerPowerEffect(CardModel card) {
    _state = _state.copyWith(powerActivatedCard: card);
    notifyListeners();

    _effectTimer?.cancel();
    _effectTimer = Timer(const Duration(milliseconds: 2200), () {
      _state = _state.copyWith(clearPowerActivated: true);
      notifyListeners();
    });
  }

  void _startPeekCountdown(int seconds) {
    _peekTimer?.cancel();
    _peekCountdown = seconds;

    // En la fase de vistazo, las 2 cartas inferiores se muestran boca arriba
    var p = myPlayer;
    if (p != null) {
      if (p.cards.length > 2 && p.cards[2] != null) p.cards[2]!.isFaceUp = true;
      if (p.cards.length > 3 && p.cards[3] != null) p.cards[3]!.isFaceUp = true;
    }

    _peekTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _peekCountdown--;
      if (_peekCountdown <= 0) {
        timer.cancel();
        // Ocultar de nuevo las cartas inferiores
        if (p != null) {
          if (p.cards.length > 2 && p.cards[2] != null) p.cards[2]!.isFaceUp = false;
          if (p.cards.length > 3 && p.cards[3] != null) p.cards[3]!.isFaceUp = false;
        }
        _state = _state.copyWith(
          phase: GamePhase.playerTurn,
          activePlayerName: _state.activePlayerName ?? myPlayerName,
          lastEventMessage: '¡Vistazo concluido! Comienza el juego de memoria.',
        );
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  // ==========================================
  // MOTOR DE SIMULACIÓN LOCAL / OFFLINE
  // Permite probar inmediatamente todas las mecánicas,
  // paridad, poderes, quemados y puntuaciones.
  // ==========================================

  void startSimulatedGame({List<String>? botNames}) {
    List<String> names = [myPlayerName, ...(botNames ?? ['BOT_ALEX', 'BOT_CARLOS'])];
    List<CardModel> deck = _generateShuffledDeck();

    List<PlayerGameState> players = [];
    for (var name in names) {
      List<CardModel?> hand = [];
      for (int i = 0; i < config.initialCardCount; i++) {
        hand.add(deck.removeLast()..isFaceUp = false);
      }
      players.add(PlayerGameState(name: name, cards: hand));
    }

    // Carta inicial en el mazo de descarte
    CardModel initialDiscard = deck.removeLast()..isFaceUp = true;

    // Rotación del jugador inicial con cada ronda
    int startingIndex = (_state.roundNumber - 1) % names.length;
    String startingPlayer = names[startingIndex];

    _state = GameState(
      roundNumber: _state.roundNumber,
      phase: GamePhase.initialPeek,
      activePlayerName: startingPlayer,
      drawPileCount: deck.length,
      discardPile: [initialDiscard],
      players: players,
      lastEventMessage: '¡Comienza la ronda ${_state.roundNumber}! Memoriza tus 2 cartas inferiores.',
    );

    _simDeck = deck;
    _startPeekCountdown(config.peekDurationSeconds);
    notifyListeners();
  }

  List<CardModel> _simDeck = [];

  List<CardModel> _generateShuffledDeck() {
    List<CardModel> deck = [];
    int idCounter = 1;

    for (var suit in [CardSuit.spades, CardSuit.hearts, CardSuit.diamonds, CardSuit.clubs]) {
      for (var rank in [
        CardRank.ace,
        CardRank.two,
        CardRank.three,
        CardRank.four,
        CardRank.five,
        CardRank.six,
        CardRank.seven,
        CardRank.eight,
        CardRank.nine,
        CardRank.ten,
        CardRank.jack,
        CardRank.queen,
        CardRank.king,
      ]) {
        deck.add(CardModel(
          id: 'card_${idCounter++}',
          suit: suit,
          rank: rank,
        ));
      }
    }

    // 2 Jokers
    deck.add(CardModel(id: 'joker_1', suit: CardSuit.joker, rank: CardRank.joker));
    deck.add(CardModel(id: 'joker_2', suit: CardSuit.joker, rank: CardRank.joker));

    deck.shuffle(Random());
    return deck;
  }

  void _simDrawCard(String from) {
    CardModel card;
    if (from == 'discard') {
      card = _state.discardPile.removeLast();
      card.isFromDiscard = true;
    } else {
      if (_simDeck.isEmpty) {
        _handleSimEmptyDeck();
        return;
      }
      card = _simDeck.removeLast();
    }
    card.isFaceUp = true;

    _state = _state.copyWith(
      phase: GamePhase.cardDrawn,
      drawnCard: card,
      drawnFrom: from,
      drawPileCount: _simDeck.length,
      lastEventMessage: '$myPlayerName robó un ${card.rankLabel}${card.suitSymbol}.',
    );
    notifyListeners();
  }

  void _simSwapDrawnCard(int slotIndex) {
    var p = myPlayer;
    if (p == null || slotIndex >= p.cards.length) return;

    CardModel? oldCard = p.cards[slotIndex];
    CardModel drawn = _state.drawnCard!;
    drawn.isFaceUp = false;
    p.cards[slotIndex] = drawn;

    if (oldCard != null) {
      oldCard.isFaceUp = true;
      _handleSimDiscardCard(oldCard);
    }
  }

  void _simDiscardDrawnCard() {
    CardModel drawn = _state.drawnCard!;
    _handleSimDiscardCard(drawn);
  }

  void _handleSimDiscardCard(CardModel card) {
    List<CardModel> newDiscard = List.from(_state.discardPile)..add(card);

    if (card.canTriggerPower && config.enableSpecialPowers) {
      _state = _state.copyWith(
        discardPile: newDiscard,
        phase: GamePhase.powerChoice,
        pendingPowerCard: card,
        clearDrawnCard: true,
        lastEventMessage: '¡Poder disponible de ${card.rankLabel}! ¿Deseas usarlo?',
      );
    } else {
      _state = _state.copyWith(
        discardPile: newDiscard,
        phase: GamePhase.playerTurn,
        clearDrawnCard: true,
        lastEventMessage: '$myPlayerName descartó un ${card.rankLabel}${card.suitSymbol}.',
      );
      _advanceSimTurn();
    }
    notifyListeners();
  }

  void _simUsePower(String powerType, {int? mySlot, String? targetPlayer, int? targetSlot}) {
    CardModel? powerCard = _state.pendingPowerCard;
    if (powerCard != null) {
      powerCard.powerUsed = true;
      _triggerPowerEffect(powerCard);
    }

    if (powerType == 'PEEK_OWN' && mySlot != null) {
      var p = myPlayer;
      if (p != null && mySlot < p.cards.length && p.cards[mySlot] != null) {
        var card = p.cards[mySlot]!;
        _handleSocketPrivatePeek({
          'card': card.toJson(),
          'targetPlayer': myPlayerName,
          'slotIndex': mySlot,
        });
      }
    } else if (powerType == 'PEEK_OTHER' && targetPlayer != null && targetSlot != null) {
      var target = _state.getPlayer(targetPlayer);
      if (target != null && targetSlot < target.cards.length && target.cards[targetSlot] != null) {
        var card = target.cards[targetSlot]!;
        _handleSocketPrivatePeek({
          'card': card.toJson(),
          'targetPlayer': targetPlayer,
          'slotIndex': targetSlot,
        });
      }
    } else if (powerType == 'SWAP' && mySlot != null && targetPlayer != null && targetSlot != null) {
      var me = myPlayer;
      var target = _state.getPlayer(targetPlayer);
      if (me != null && target != null) {
        CardModel? myC = me.cards[mySlot];
        CardModel? targetC = target.cards[targetSlot];

        me.cards[mySlot] = targetC;
        target.cards[targetSlot] = myC;

        _state = _state.copyWith(
          lastEventMessage: '¡Intercambiaste tu carta slot $mySlot con la de $targetPlayer slot $targetSlot!',
        );
      }
    }

    _state = _state.copyWith(
      clearPendingPower: true,
      phase: GamePhase.playerTurn,
    );
    _advanceSimTurn();
    notifyListeners();
  }

  void _simClaimParity(String targetPlayer, int slotIndex) {
    CardModel? top = _state.topDiscard;
    if (top == null) return;

    var target = _state.getPlayer(targetPlayer);
    if (target == null || slotIndex >= target.cards.length || target.cards[slotIndex] == null) return;

    CardModel candidate = target.cards[slotIndex]!;
    bool isMatch = candidate.rank == top.rank;
    bool isMine = targetPlayer == myPlayerName;

    if (isMatch) {
      // Éxito de paridad: carta quemada
      candidate.isBurned = true;
      _triggerBurnEffect(candidate);

      if (isMine) {
        // Atinó y era suya: se queda con 1 carta menos
        target.cards[slotIndex] = null;
        _state = _state.copyWith(
          lastEventMessage: '🎯 ¡Acertaste paridad con tu carta! Ahora tienes 1 carta menos.',
        );
      } else {
        // Atinó y no era suya: quita la del rival y le da una propia
        target.cards[slotIndex] = null;
        var me = myPlayer;
        int myIndexWithCard = me?.cards.indexWhere((c) => c != null) ?? -1;
        if (me != null && myIndexWithCard != -1) {
          CardModel myCard = me.cards[myIndexWithCard]!;
          me.cards[myIndexWithCard] = null;
          target.cards[slotIndex] = myCard;
        }
        _state = _state.copyWith(
          lastEventMessage: '🎯 ¡Paridad acertada con carta de $targetPlayer! Le diste una tuya a cambio.',
        );
      }
    } else {
      // Fallo de paridad
      if (isMine) {
        // Falló y era suya: se queda con su carta + carta de castigo (+1 carta)
        CardModel penaltyCard = _simDeck.isNotEmpty ? _simDeck.removeLast() : top;
        penaltyCard.isFaceUp = false;
        target.cards.add(penaltyCard);
        _state = _state.copyWith(
          lastEventMessage: '❌ Fallaste paridad con tu carta. Recibes carta de penalización (+1).',
        );
      } else {
        // Falló y era ajena: se queda con ambas cartas y el rival queda con -1
        target.cards[slotIndex] = null;
        var me = myPlayer;
        if (me != null) {
          candidate.isFaceUp = false;
          me.cards.add(candidate);
          if (_simDeck.isNotEmpty) {
            CardModel penalty = _simDeck.removeLast()..isFaceUp = false;
            me.cards.add(penalty);
          }
        }
        _state = _state.copyWith(
          lastEventMessage: '❌ Fallaste paridad sobre $targetPlayer. Te llevas 2 cartas y el rival se beneficia (-1).',
        );
      }
    }

    notifyListeners();
  }

  void _simCallLowest(String callerName) {
    // Revelar todas las cartas de todos los jugadores
    for (var p in _state.players) {
      for (var c in p.cards) {
        if (c != null) c.isFaceUp = true;
      }
    }

    var caller = _state.getPlayer(callerName)!;
    int callerScore = caller.calculatedCardsSum;

    // Verificar si el caller tiene estrictamente la menor puntuación
    bool isStrictlyLowest = true;
    for (var p in _state.players) {
      if (p.name != callerName && p.calculatedCardsSum <= callerScore) {
        isStrictlyLowest = false; // Menor o empate cuenta como fallo
        break;
      }
    }

    // Calcular puntajes de la ronda
    for (var p in _state.players) {
      int cardSum = p.calculatedCardsSum;
      if (p.name == callerName) {
        if (isStrictlyLowest) {
          p.roundScore = cardSum + config.lowestCallerBonus; // -10 bonificación
        } else {
          p.roundScore = cardSum + config.lowestCallerPenalty; // +30 penalización
        }
      } else {
        p.roundScore = cardSum;
      }
      p.totalScore += p.roundScore;
    }

    _state = _state.copyWith(
      phase: GamePhase.roundEnd,
      roundEndReason: 'CALLED_LOW',
      roundEndCaller: callerName,
      lastEventMessage: isStrictlyLowest
          ? '🏆 ¡$callerName tenía razón y recibe bonificación de ${config.lowestCallerBonus} pts!'
          : '⚠️ ¡$callerName se equivocó y recibe penalización de +${config.lowestCallerPenalty} pts!',
    );
    notifyListeners();
  }

  void _handleSimEmptyDeck() {
    // Caso 3: Mazo agotado -> el de menor puntuación recibe +100
    for (var p in _state.players) {
      for (var c in p.cards) {
        if (c != null) c.isFaceUp = true;
      }
    }

    int minScore = 99999;
    for (var p in _state.players) {
      int score = p.calculatedCardsSum;
      if (score < minScore) minScore = score;
    }

    for (var p in _state.players) {
      int cardSum = p.calculatedCardsSum;
      if (cardSum == minScore) {
        p.roundScore = cardSum + config.deckEmptyPenalty; // +100
      } else {
        p.roundScore = cardSum;
      }
      p.totalScore += p.roundScore;
    }

    _state = _state.copyWith(
      phase: GamePhase.roundEnd,
      roundEndReason: 'DECK_EMPTY',
      lastEventMessage: '⚠️ ¡Se agotó el mazo! El jugador con menor puntuación recibe +${config.deckEmptyPenalty} pts.',
    );
    notifyListeners();
  }

  void _advanceSimTurn() {
    int currentIndex = _state.players.indexWhere((p) => p.name == _state.activePlayerName);
    int nextIndex = (currentIndex + 1) % _state.players.length;
    String nextPlayer = _state.players[nextIndex].name;

    // Caso 2: si el siguiente jugador tiene 0 cartas, canta automáticamente
    var nextP = _state.getPlayer(nextPlayer);
    if (nextP != null && nextP.hasZeroCards) {
      _simCallLowest(nextPlayer);
      return;
    }

    _state = _state.copyWith(
      activePlayerName: nextPlayer,
      phase: GamePhase.playerTurn,
      clearDrawnCard: true,
      lastEventMessage: nextPlayer == myPlayerName ? '¡Es tu turno!' : 'Turno de $nextPlayer',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _peekTimer?.cancel();
    _effectTimer?.cancel();
    super.dispose();
  }
}
