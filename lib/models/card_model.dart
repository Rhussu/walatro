enum CardSuit { spades, hearts, diamonds, clubs, joker }

enum CardRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  joker,
}

enum CardPowerType {
  none,
  peekOwn, // 7
  peekOther, // 8
  swapCards, // 9
}

class CardModel {
  final String id;
  final CardSuit suit;
  final CardRank rank;
  bool isFaceUp;
  bool isBurned; // Quemada por paridad
  bool powerUsed; // Si ya se activó su efecto especial
  bool isFromDiscard; // Si fue recogida del mazo de descarte

  CardModel({
    required this.id,
    required this.suit,
    required this.rank,
    this.isFaceUp = false,
    this.isBurned = false,
    this.powerUsed = false,
    this.isFromDiscard = false,
  });

  /// Valor en puntos según las reglas:
  /// - A al 10: 1 a 10
  /// - J, Q, K: 10
  /// - K de Picas: -1
  /// - Jokers: 0
  int get scoreValue {
    if (rank == CardRank.joker) return 0;
    if (rank == CardRank.king && suit == CardSuit.spades) return -1;
    switch (rank) {
      case CardRank.ace:
        return 1;
      case CardRank.two:
        return 2;
      case CardRank.three:
        return 3;
      case CardRank.four:
        return 4;
      case CardRank.five:
        return 5;
      case CardRank.six:
        return 6;
      case CardRank.seven:
        return 7;
      case CardRank.eight:
        return 8;
      case CardRank.nine:
        return 9;
      case CardRank.ten:
      case CardRank.jack:
      case CardRank.queen:
      case CardRank.king:
        return 10;
      case CardRank.joker:
        return 0;
    }
  }

  /// Tipo de poder asociado a la carta
  CardPowerType get powerType {
    if (rank == CardRank.seven) return CardPowerType.peekOwn;
    if (rank == CardRank.eight) return CardPowerType.peekOther;
    if (rank == CardRank.nine) return CardPowerType.swapCards;
    return CardPowerType.none;
  }

  /// ¿Tiene un poder disponible para ser utilizado?
  /// Solo cartas 7, 8 o 9 que NO hayan sido quemadas por paridad,
  /// que no se les haya gastado el poder y que no vengan del descarte.
  bool get canTriggerPower {
    return powerType != CardPowerType.none &&
        !powerUsed &&
        !isBurned &&
        !isFromDiscard;
  }

  /// ¿Puede ser robada del mazo de descarte?
  /// Condición: no haber sido quemada por paridad.
  bool get canPickFromDiscard {
    return !isBurned;
  }

  /// Texto legible del rango (ej. 'A', '7', '10', 'K', 'JK')
  String get rankLabel {
    switch (rank) {
      case CardRank.ace:
        return 'A';
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.eight:
        return '8';
      case CardRank.nine:
        return '9';
      case CardRank.ten:
        return '10';
      case CardRank.jack:
        return 'J';
      case CardRank.queen:
        return 'Q';
      case CardRank.king:
        return 'K';
      case CardRank.joker:
        return 'JK';
    }
  }

  /// Símbolo del palo
  String get suitSymbol {
    switch (suit) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
      case CardSuit.joker:
        return '★';
    }
  }

  /// ¿Es palo rojo?
  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;

  CardModel copyWith({
    String? id,
    CardSuit? suit,
    CardRank? rank,
    bool? isFaceUp,
    bool? isBurned,
    bool? powerUsed,
    bool? isFromDiscard,
  }) {
    return CardModel(
      id: id ?? this.id,
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isBurned: isBurned ?? this.isBurned,
      powerUsed: powerUsed ?? this.powerUsed,
      isFromDiscard: isFromDiscard ?? this.isFromDiscard,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suit': suit.name,
      'rank': rank.name,
      'isFaceUp': isFaceUp,
      'isBurned': isBurned,
      'powerUsed': powerUsed,
      'isFromDiscard': isFromDiscard,
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      suit: CardSuit.values.firstWhere(
        (s) => s.name == json['suit'],
        orElse: () => CardSuit.spades,
      ),
      rank: CardRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => CardRank.ace,
      ),
      isFaceUp: json['isFaceUp'] as bool? ?? false,
      isBurned: json['isBurned'] as bool? ?? false,
      powerUsed: json['powerUsed'] as bool? ?? false,
      isFromDiscard: json['isFromDiscard'] as bool? ?? false,
    );
  }

  @override
  String toString() => '$rankLabel$suitSymbol';
}
