import 'package:flutter_test/flutter_test.dart';
import 'package:walatro/models/card_model.dart';
import 'package:walatro/models/game_config.dart';
import 'package:walatro/models/game_state.dart';
import 'package:walatro/models/player_game_state.dart';
import 'package:walatro/services/game_controller.dart';

void main() {
  group('CardModel Value & Rule Tests', () {
    test('Standard card point values', () {
      final ace = CardModel(id: '1', suit: CardSuit.hearts, rank: CardRank.ace);
      expect(ace.scoreValue, equals(1));

      final five = CardModel(id: '2', suit: CardSuit.diamonds, rank: CardRank.five);
      expect(five.scoreValue, equals(5));

      final jack = CardModel(id: '3', suit: CardSuit.clubs, rank: CardRank.jack);
      expect(jack.scoreValue, equals(10));

      final queen = CardModel(id: '4', suit: CardSuit.hearts, rank: CardRank.queen);
      expect(queen.scoreValue, equals(10));

      final regularKing = CardModel(id: '5', suit: CardSuit.hearts, rank: CardRank.king);
      expect(regularKing.scoreValue, equals(10));
    });

    test('King of Spades special rule (-1 points)', () {
      final kingOfSpades = CardModel(id: 'k_spades', suit: CardSuit.spades, rank: CardRank.king);
      expect(kingOfSpades.scoreValue, equals(-1));
    });

    test('Joker special rule (0 points)', () {
      final joker = CardModel(id: 'joker_1', suit: CardSuit.joker, rank: CardRank.joker);
      expect(joker.scoreValue, equals(0));
    });

    test('Discard pick condition: cannot pick if burned', () {
      final normalDiscard = CardModel(
        id: 'c1',
        suit: CardSuit.diamonds,
        rank: CardRank.seven,
        isBurned: false,
      );
      expect(normalDiscard.canPickFromDiscard, isTrue);

      final burnedDiscard = CardModel(
        id: 'c2',
        suit: CardSuit.diamonds,
        rank: CardRank.seven,
        isBurned: true,
      );
      expect(burnedDiscard.canPickFromDiscard, isFalse);
    });

    test('JSON serialization & deserialization', () {
      final card = CardModel(
        id: 'test_card',
        suit: CardSuit.spades,
        rank: CardRank.king,
        isFaceUp: true,
        isBurned: false,
        powerUsed: true,
      );

      final json = card.toJson();
      final restored = CardModel.fromJson(json);

      expect(restored.id, equals(card.id));
      expect(restored.suit, equals(CardSuit.spades));
      expect(restored.rank, equals(CardRank.king));
      expect(restored.scoreValue, equals(-1));
      expect(restored.powerUsed, isTrue);
    });
  });

  group('GameController & Scoring Tests', () {
    test('Simulated game initialization setup', () {
      final controller = GameController(myPlayerName: 'HERO');
      controller.startSimulatedGame();

      expect(controller.state.players.length, equals(3));
      expect(controller.myPlayer, isNotNull);
      expect(controller.myPlayer!.cards.length, equals(4));

      // Bottom cards are face up initially
      expect(controller.myPlayer!.cards[2]?.isFaceUp, isTrue);
      expect(controller.myPlayer!.cards[3]?.isFaceUp, isTrue);
      // Top cards are face down initially
      expect(controller.myPlayer!.cards[0]?.isFaceUp, isFalse);
      expect(controller.myPlayer!.cards[1]?.isFaceUp, isFalse);

      expect(controller.state.phase, equals(GamePhase.initialPeek));
      controller.dispose();
    });

    test('Parity arm toggle', () {
      final controller = GameController(myPlayerName: 'HERO');
      controller.startSimulatedGame();

      expect(controller.isParityArmed, isFalse);
      controller.toggleParityArm();
      expect(controller.isParityArmed, isTrue);
      controller.toggleParityArm();
      expect(controller.isParityArmed, isFalse);

      controller.dispose();
    });

    test('PlayerGameState total points calculation', () {
      final player = PlayerGameState(
        name: 'TESTER',
        cards: [
          CardModel(id: '1', suit: CardSuit.spades, rank: CardRank.king), // -1
          CardModel(id: '2', suit: CardSuit.joker, rank: CardRank.joker), // 0
          CardModel(id: '3', suit: CardSuit.hearts, rank: CardRank.five), // 5
          CardModel(id: '4', suit: CardSuit.clubs, rank: CardRank.ace),   // 1
        ],
      );

      expect(player.calculatedCardsSum, equals(5)); // -1 + 0 + 5 + 1 = 5
    });

    test('Config parameters match game design', () {
      const config = GameConfig();
      expect(config.lowestCallerBonus, equals(-10));
      expect(config.lowestCallerPenalty, equals(30));
      expect(config.deckEmptyPenalty, equals(100));
      expect(config.peekDurationSeconds, equals(5));
    });
  });
}
