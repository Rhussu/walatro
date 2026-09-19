import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walatro/models/table_score_model.dart';
import 'package:walatro/screens/table_scorekeeper_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TableScoreState Scoring Logic Tests', () {
    test('Canto "Soy el que tiene menos" con ACIERTO estricto (-10 bonus)', () {
      final scores = TableScoreState.computeRoundScores(
        rawScores: {'p1': 5, 'p2': 12, 'p3': 8},
        endType: RoundEndType.calledLow,
        callerPlayerId: 'p1',
      );

      expect(scores['p1']!.rawPoints, equals(5));
      expect(scores['p1']!.modifier, equals(-10));
      expect(scores['p1']!.totalPoints, equals(-5)); // 5 - 10 = -5

      expect(scores['p2']!.rawPoints, equals(12));
      expect(scores['p2']!.modifier, equals(0));
      expect(scores['p2']!.totalPoints, equals(12));

      expect(scores['p3']!.rawPoints, equals(8));
      expect(scores['p3']!.modifier, equals(0));
      expect(scores['p3']!.totalPoints, equals(8));
    });

    test('Canto "Soy el que tiene menos" con FALLO (+30 penalización)', () {
      final scores = TableScoreState.computeRoundScores(
        rawScores: {'p1': 17, 'p2': 9},
        endType: RoundEndType.calledLow,
        callerPlayerId: 'p1',
      );

      // P1 cantó pero tenía 17 vs 9 del rival -> Penalización +30
      expect(scores['p1']!.rawPoints, equals(17));
      expect(scores['p1']!.modifier, equals(30));
      expect(scores['p1']!.totalPoints, equals(47)); // 17 + 30 = 47

      expect(scores['p2']!.rawPoints, equals(9));
      expect(scores['p2']!.modifier, equals(0));
      expect(scores['p2']!.totalPoints, equals(9));
    });

    test('Canto "Soy el que tiene menos" con EMPATE (+30 penalización por no ser menor estricto)', () {
      final scores = TableScoreState.computeRoundScores(
        rawScores: {'p1': 8, 'p2': 8},
        endType: RoundEndType.calledLow,
        callerPlayerId: 'p1',
      );

      // Empate: según reglas, solo acierta si es estrictamente menor
      expect(scores['p1']!.rawPoints, equals(8));
      expect(scores['p1']!.modifier, equals(30));
      expect(scores['p1']!.totalPoints, equals(38));

      expect(scores['p2']!.rawPoints, equals(8));
      expect(scores['p2']!.modifier, equals(0));
    });

    test('Mazo de robo agotado (+100 penalización al menor)', () {
      final scores = TableScoreState.computeRoundScores(
        rawScores: {'p1': 4, 'p2': 15, 'p3': 11},
        endType: RoundEndType.deckEmpty,
      );

      // P1 tiene el menor puntaje (4) -> penalización de +100
      expect(scores['p1']!.rawPoints, equals(4));
      expect(scores['p1']!.modifier, equals(100));
      expect(scores['p1']!.totalPoints, equals(104));

      expect(scores['p2']!.rawPoints, equals(15));
      expect(scores['p2']!.modifier, equals(0));

      expect(scores['p3']!.rawPoints, equals(11));
      expect(scores['p3']!.modifier, equals(0));
    });

    test('Fin normal sin bonificaciones', () {
      final scores = TableScoreState.computeRoundScores(
        rawScores: {'p1': 10, 'p2': 14},
        endType: RoundEndType.normal,
      );

      expect(scores['p1']!.modifier, equals(0));
      expect(scores['p1']!.totalPoints, equals(10));
      expect(scores['p2']!.modifier, equals(0));
      expect(scores['p2']!.totalPoints, equals(14));
    });

    test('Serialización y deserialización JSON completa de TableScoreState', () {
      final state = TableScoreState(
        players: const [
          TablePlayer(id: 'p1', name: 'ANA'),
          TablePlayer(id: 'p2', name: 'JUAN'),
        ],
        targetRounds: 3,
        rounds: [
          TableRound(
            roundNumber: 1,
            endType: RoundEndType.calledLow,
            callerPlayerId: 'p1',
            scores: {
              'p1': const PlayerRoundScore(rawPoints: 17, modifier: 30, modifierLabel: '+30'),
              'p2': const PlayerRoundScore(rawPoints: 8, modifier: 0),
            },
          ),
        ],
      );

      final json = state.toJson();
      final restored = TableScoreState.fromJson(json);

      expect(restored.players.length, equals(2));
      expect(restored.players[0].name, equals('ANA'));
      expect(restored.targetRounds, equals(3));
      expect(restored.rounds.length, equals(1));
      expect(restored.rounds[0].scores['p1']!.rawPoints, equals(17));
      expect(restored.rounds[0].scores['p1']!.modifier, equals(30));
      expect(restored.rounds[0].scores['p1']!.totalPoints, equals(47));
      expect(restored.totalScoreForPlayer('p1'), equals(47));
      expect(restored.totalScoreForPlayer('p2'), equals(8));
      expect(restored.getLeadingPlayerIds(), equals(['p2']));
    });
  });

  group('TableScorekeeperScreen Widget Tests', () {
    testWidgets('Renderiza tabla, controles y botón para agregar jugadores',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: TableScorekeeperScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que el título y controles están presentes
      expect(find.text('ANOTADOR DE MESA'), findsOneWidget);
      expect(find.text('RONDAS: '), findsOneWidget);
      expect(find.text('+ JUGADOR'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('JUGADOR 1'), findsOneWidget);
      expect(find.text('JUGADOR 2'), findsOneWidget);

      // Probar pulsar botón + JUGADOR
      await tester.tap(find.text('+ JUGADOR'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('NUEVO JUGADOR'), findsOneWidget);
      expect(find.text('AGREGAR'), findsOneWidget);

      // Cerrar diálogo
      await tester.tap(find.text('CANCELAR'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar botón para anotar ronda 1
      expect(find.text('ANOTAR RONDA 1'), findsOneWidget);
    });
  });
}
