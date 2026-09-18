/// Configuración modular y reajustable de las reglas del juego.
/// Permite modificar tiempos, penalizaciones, bonificaciones y variantes
/// sin alterar la lógica central del motor.
class GameConfig {
  /// Tiempo en segundos para que los jugadores memoricen sus 2 cartas inferiores al iniciar la ronda
  final int peekDurationSeconds;

  /// Cantidad de cartas iniciales por jugador (típicamente 4 dispuestas en 2x2)
  final int initialCardCount;

  /// Bonificación al jugador que cantó "Soy el que tiene menos" si acertó (-10 puntos)
  final int lowestCallerBonus;

  /// Penalización al jugador que cantó si falló o empató (+30 puntos)
  final int lowestCallerPenalty;

  /// Penalización al jugador con menos puntos si el mazo de robo se agota (+100 puntos)
  final int deckEmptyPenalty;

  /// Puntaje objetivo acumulado en el que un jugador pierde o concluye la partida
  final int maxScoreTarget;

  /// ¿Se permiten los poderes especiales de 7, 8 y 9?
  final bool enableSpecialPowers;

  /// ¿La paridad con carta ajena está habilitada?
  final bool enableOpponentParity;

  const GameConfig({
    this.peekDurationSeconds = 5,
    this.initialCardCount = 4,
    this.lowestCallerBonus = -10,
    this.lowestCallerPenalty = 30,
    this.deckEmptyPenalty = 100,
    this.maxScoreTarget = 100,
    this.enableSpecialPowers = true,
    this.enableOpponentParity = true,
  });

  GameConfig copyWith({
    int? peekDurationSeconds,
    int? initialCardCount,
    int? lowestCallerBonus,
    int? lowestCallerPenalty,
    int? deckEmptyPenalty,
    int? maxScoreTarget,
    bool? enableSpecialPowers,
    bool? enableOpponentParity,
  }) {
    return GameConfig(
      peekDurationSeconds: peekDurationSeconds ?? this.peekDurationSeconds,
      initialCardCount: initialCardCount ?? this.initialCardCount,
      lowestCallerBonus: lowestCallerBonus ?? this.lowestCallerBonus,
      lowestCallerPenalty: lowestCallerPenalty ?? this.lowestCallerPenalty,
      deckEmptyPenalty: deckEmptyPenalty ?? this.deckEmptyPenalty,
      maxScoreTarget: maxScoreTarget ?? this.maxScoreTarget,
      enableSpecialPowers: enableSpecialPowers ?? this.enableSpecialPowers,
      enableOpponentParity: enableOpponentParity ?? this.enableOpponentParity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peekDurationSeconds': peekDurationSeconds,
      'initialCardCount': initialCardCount,
      'lowestCallerBonus': lowestCallerBonus,
      'lowestCallerPenalty': lowestCallerPenalty,
      'deckEmptyPenalty': deckEmptyPenalty,
      'maxScoreTarget': maxScoreTarget,
      'enableSpecialPowers': enableSpecialPowers,
      'enableOpponentParity': enableOpponentParity,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      peekDurationSeconds: json['peekDurationSeconds'] ?? 5,
      initialCardCount: json['initialCardCount'] ?? 4,
      lowestCallerBonus: json['lowestCallerBonus'] ?? -10,
      lowestCallerPenalty: json['lowestCallerPenalty'] ?? 30,
      deckEmptyPenalty: json['deckEmptyPenalty'] ?? 100,
      maxScoreTarget: json['maxScoreTarget'] ?? 100,
      enableSpecialPowers: json['enableSpecialPowers'] ?? true,
      enableOpponentParity: json['enableOpponentParity'] ?? true,
    );
  }
}
