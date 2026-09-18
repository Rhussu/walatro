import 'package:walatro/models/card_model.dart';

class PlayerGameState {
  final String name;
  final bool isHost;
  bool isReady;
  
  /// Cartas del jugador en posiciones fijas.
  /// Generalmente inicia con 4 cartas (índices 0, 1 arriba; 2, 3 abajo).
  /// Si pierde una carta por paridad, el slot queda null o se reduce.
  /// Si recibe una penalización, se añade un nuevo slot.
  List<CardModel?> cards;

  int roundScore;
  int totalScore;
  bool hasCalledLowest;

  PlayerGameState({
    required this.name,
    this.isHost = false,
    this.isReady = false,
    List<CardModel?>? cards,
    this.roundScore = 0,
    this.totalScore = 0,
    this.hasCalledLowest = false,
  }) : cards = cards ?? [];

  int get cardCount => cards.where((c) => c != null).length;

  bool get hasZeroCards => cardCount == 0;

  /// Suma de los valores de todas sus cartas visibles/activas actuales
  int get calculatedCardsSum {
    int sum = 0;
    for (var card in cards) {
      if (card != null) {
        sum += card.scoreValue;
      }
    }
    return sum;
  }

  PlayerGameState copyWith({
    String? name,
    bool? isHost,
    bool? isReady,
    List<CardModel?>? cards,
    int? roundScore,
    int? totalScore,
    bool? hasCalledLowest,
  }) {
    return PlayerGameState(
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      cards: cards != null
          ? List<CardModel?>.from(cards)
          : List<CardModel?>.from(this.cards),
      roundScore: roundScore ?? this.roundScore,
      totalScore: totalScore ?? this.totalScore,
      hasCalledLowest: hasCalledLowest ?? this.hasCalledLowest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isHost': isHost,
      'isReady': isReady,
      'cards': cards.map((c) => c?.toJson()).toList(),
      'roundScore': roundScore,
      'totalScore': totalScore,
      'hasCalledLowest': hasCalledLowest,
    };
  }

  factory PlayerGameState.fromJson(Map<String, dynamic> json) {
    var rawCards = json['cards'] as List?;
    List<CardModel?> parsedCards = [];
    if (rawCards != null) {
      parsedCards = rawCards.map((c) {
        if (c == null) return null;
        return CardModel.fromJson(Map<String, dynamic>.from(c));
      }).toList();
    }

    return PlayerGameState(
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isReady: json['isReady'] as bool? ?? false,
      cards: parsedCards,
      roundScore: json['roundScore'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      hasCalledLowest: json['hasCalledLowest'] as bool? ?? false,
    );
  }
}
