/// Modelos de datos para el Anotador de Mesa (Contador Presencial) de Walatro.
library;

enum RoundEndType {
  calledLow, // Alguien cantó "Soy el que tiene menos"
  zeroCards, // Un jugador se quedó con 0 cartas
  deckEmpty, // Se agotó el mazo de robo
  normal,    // Fin manual sin modificadores especiales
}

class PlayerRoundScore {
  final int rawPoints;
  final int modifier; // -10, +30, +100, 0
  final String? modifierLabel;

  const PlayerRoundScore({
    required this.rawPoints,
    this.modifier = 0,
    this.modifierLabel,
  });

  int get totalPoints => rawPoints + modifier;

  Map<String, dynamic> toJson() => {
        'rawPoints': rawPoints,
        'modifier': modifier,
        'modifierLabel': modifierLabel,
      };

  factory PlayerRoundScore.fromJson(Map<String, dynamic> json) =>
      PlayerRoundScore(
        rawPoints: json['rawPoints'] as int? ?? 0,
        modifier: json['modifier'] as int? ?? 0,
        modifierLabel: json['modifierLabel'] as String?,
      );
}

class TablePlayer {
  final String id;
  final String name;

  const TablePlayer({required this.id, required this.name});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory TablePlayer.fromJson(Map<String, dynamic> json) => TablePlayer(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  TablePlayer copyWith({String? id, String? name}) => TablePlayer(
        id: id ?? this.id,
        name: name ?? this.name,
      );
}

class TableRound {
  final int roundNumber;
  final RoundEndType endType;
  final String? callerPlayerId;
  final Map<String, PlayerRoundScore> scores; // playerId -> score

  const TableRound({
    required this.roundNumber,
    required this.endType,
    this.callerPlayerId,
    required this.scores,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'endType': endType.name,
        'callerPlayerId': callerPlayerId,
        'scores': scores.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory TableRound.fromJson(Map<String, dynamic> json) {
    final scoresMap = (json['scores'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, PlayerRoundScore.fromJson(v as Map<String, dynamic>)),
    );

    return TableRound(
      roundNumber: json['roundNumber'] as int? ?? 1,
      endType: RoundEndType.values.firstWhere(
        (e) => e.name == json['endType'],
        orElse: () => RoundEndType.normal,
      ),
      callerPlayerId: json['callerPlayerId'] as String?,
      scores: scoresMap,
    );
  }
}

class TableScoreState {
  final List<TablePlayer> players;
  final int targetRounds;
  final List<TableRound> rounds;

  const TableScoreState({
    required this.players,
    this.targetRounds = 5,
    this.rounds = const [],
  });

  static TableScoreState createDefault() {
    return const TableScoreState(
      players: [
        TablePlayer(id: 'p1', name: 'JUGADOR 1'),
        TablePlayer(id: 'p2', name: 'JUGADOR 2'),
      ],
      targetRounds: 5,
      rounds: [],
    );
  }

  int totalScoreForPlayer(String playerId) {
    int total = 0;
    for (final round in rounds) {
      final score = round.scores[playerId];
      if (score != null) {
        total += score.totalPoints;
      }
    }
    return total;
  }

  int totalRawScoreForPlayer(String playerId) {
    int total = 0;
    for (final round in rounds) {
      final score = round.scores[playerId];
      if (score != null) {
        total += score.rawPoints;
      }
    }
    return total;
  }

  List<String> getLeadingPlayerIds() {
    if (players.isEmpty) return [];
    if (rounds.isEmpty) return players.map((p) => p.id).toList();

    int minScore = totalScoreForPlayer(players.first.id);
    for (final player in players) {
      final score = totalScoreForPlayer(player.id);
      if (score < minScore) {
        minScore = score;
      }
    }

    return players
        .where((p) => totalScoreForPlayer(p.id) == minScore)
        .map((p) => p.id)
        .toList();
  }

  /// Calcula las puntuaciones finales de una ronda dados los puntos brutos de las cartas
  /// y el motivo de fin según las reglas oficiales de Walatro.
  static Map<String, PlayerRoundScore> computeRoundScores({
    required Map<String, int> rawScores,
    required RoundEndType endType,
    String? callerPlayerId,
  }) {
    final Map<String, PlayerRoundScore> result = {};

    if (rawScores.isEmpty) return result;

    if (endType == RoundEndType.calledLow || endType == RoundEndType.zeroCards) {
      // Regla Caso 1 y 2:
      // Si el que cantó tiene estrictamente la menor suma de cartas: -10 puntos
      // Si falló o empató con otro jugador: +30 puntos
      final callerScore = rawScores[callerPlayerId];

      if (callerPlayerId != null && callerScore != null) {
        bool hasStrictlyLowest = true;
        for (final entry in rawScores.entries) {
          if (entry.key != callerPlayerId && entry.value <= callerScore) {
            hasStrictlyLowest = false;
            break;
          }
        }

        for (final entry in rawScores.entries) {
          if (entry.key == callerPlayerId) {
            if (hasStrictlyLowest) {
              result[entry.key] = PlayerRoundScore(
                rawPoints: entry.value,
                modifier: -10,
                modifierLabel: 'BONUS -10',
              );
            } else {
              result[entry.key] = PlayerRoundScore(
                rawPoints: entry.value,
                modifier: 30,
                modifierLabel: 'PENALIZACIÓN +30',
              );
            }
          } else {
            result[entry.key] = PlayerRoundScore(rawPoints: entry.value);
          }
        }
        return result;
      }
    } else if (endType == RoundEndType.deckEmpty) {
      // Regla Caso 3:
      // El jugador que tenga MENOS puntos recibe penalización de +100 puntos
      int minVal = rawScores.values.first;
      for (final val in rawScores.values) {
        if (val < minVal) minVal = val;
      }

      // Los que tengan la menor puntuación reciben +100
      for (final entry in rawScores.entries) {
        if (entry.value == minVal) {
          result[entry.key] = PlayerRoundScore(
            rawPoints: entry.value,
            modifier: 100,
            modifierLabel: 'PENALIZACIÓN +100',
          );
        } else {
          result[entry.key] = PlayerRoundScore(rawPoints: entry.value);
        }
      }
      return result;
    }

    // Caso Normal: sin modificadores
    for (final entry in rawScores.entries) {
      result[entry.key] = PlayerRoundScore(rawPoints: entry.value);
    }
    return result;
  }

  TableScoreState copyWith({
    List<TablePlayer>? players,
    int? targetRounds,
    List<TableRound>? rounds,
  }) {
    return TableScoreState(
      players: players ?? this.players,
      targetRounds: targetRounds ?? this.targetRounds,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'targetRounds': targetRounds,
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory TableScoreState.fromJson(Map<String, dynamic> json) {
    final players = (json['players'] as List<dynamic>? ?? [])
        .map((p) => TablePlayer.fromJson(p as Map<String, dynamic>))
        .toList();

    final rounds = (json['rounds'] as List<dynamic>? ?? [])
        .map((r) => TableRound.fromJson(r as Map<String, dynamic>))
        .toList();

    return TableScoreState(
      players: players.isNotEmpty
          ? players
          : [
              const TablePlayer(id: 'p1', name: 'JUGADOR 1'),
              const TablePlayer(id: 'p2', name: 'JUGADOR 2'),
            ],
      targetRounds: json['targetRounds'] as int? ?? 5,
      rounds: rounds,
    );
  }
}
