const test = require('node:test');
const assert = require('node:assert/strict');
const {
  CardSuit,
  CardRank,
  getCardScoreValue,
  createDeck,
  canTriggerPower,
  calculatePlayerCardsSum,
  calculateRoundScores,
  resolveParity
} = require('../gameLogic');

test('Deck generation has 54 cards with correct counts', () => {
  const deck = createDeck();
  assert.equal(deck.length, 54);

  const jokers = deck.filter(c => c.rank === CardRank.JOKER);
  assert.equal(jokers.length, 2);

  const kingOfSpades = deck.find(c => c.rank === CardRank.KING && c.suit === CardSuit.SPADES);
  assert.ok(kingOfSpades);
});

test('Card point values follow Walatro rules', () => {
  assert.equal(getCardScoreValue({ rank: CardRank.ACE, suit: CardSuit.HEARTS }), 1);
  assert.equal(getCardScoreValue({ rank: CardRank.FIVE, suit: CardSuit.DIAMONDS }), 5);
  assert.equal(getCardScoreValue({ rank: CardRank.JACK, suit: CardSuit.CLUBS }), 10);
  assert.equal(getCardScoreValue({ rank: CardRank.QUEEN, suit: CardSuit.HEARTS }), 10);
  assert.equal(getCardScoreValue({ rank: CardRank.KING, suit: CardSuit.HEARTS }), 10);
  // Excepción Rey de Picas: -1
  assert.equal(getCardScoreValue({ rank: CardRank.KING, suit: CardSuit.SPADES }), -1);
  // Excepción Joker: 0
  assert.equal(getCardScoreValue({ rank: CardRank.JOKER, suit: CardSuit.JOKER }), 0);
});

test('canTriggerPower only triggers on valid 7, 8, 9', () => {
  const seven = { rank: CardRank.SEVEN, powerUsed: false, isBurned: false, isFromDiscard: false };
  assert.equal(canTriggerPower(seven), true);

  const eight = { rank: CardRank.EIGHT, powerUsed: false, isBurned: false, isFromDiscard: false };
  assert.equal(canTriggerPower(eight), true);

  const nine = { rank: CardRank.NINE, powerUsed: false, isBurned: false, isFromDiscard: false };
  assert.equal(canTriggerPower(nine), true);

  // Ya gastado
  assert.equal(canTriggerPower({ ...seven, powerUsed: true }), false);
  // Quemado
  assert.equal(canTriggerPower({ ...seven, isBurned: true }), false);
  // Viene del descarte
  assert.equal(canTriggerPower({ ...seven, isFromDiscard: true }), false);
  // Carta sin poder
  assert.equal(canTriggerPower({ rank: CardRank.TEN, powerUsed: false, isBurned: false, isFromDiscard: false }), false);
});

test('Round end scores: CALLED_LOW successful gives -10', () => {
  const players = [
    { name: 'Alice', cards: [{ rank: CardRank.ACE, suit: CardSuit.HEARTS }], totalScore: 0 }, // 1 pt
    { name: 'Bob', cards: [{ rank: CardRank.FIVE, suit: CardSuit.HEARTS }], totalScore: 0 }    // 5 pts
  ];

  const results = calculateRoundScores(players, 'Alice', 'CALLED_LOW');
  const aliceRes = results.find(r => r.name === 'Alice');
  const bobRes = results.find(r => r.name === 'Bob');

  assert.equal(aliceRes.roundScore, -9); // 1 - 10 = -9
  assert.equal(bobRes.roundScore, 5);
});

test('Round end scores: CALLED_LOW failed or tied gives +30', () => {
  const players = [
    { name: 'Alice', cards: [{ rank: CardRank.FIVE, suit: CardSuit.HEARTS }], totalScore: 0 }, // 5 pts
    { name: 'Bob', cards: [{ rank: CardRank.FIVE, suit: CardSuit.CLUBS }], totalScore: 0 }     // 5 pts (empate!)
  ];

  const results = calculateRoundScores(players, 'Alice', 'CALLED_LOW');
  const aliceRes = results.find(r => r.name === 'Alice');
  assert.equal(aliceRes.roundScore, 35); // 5 + 30 = 35 debido a empate
});

test('Round end scores: DECK_EMPTY penalizes lowest with +100', () => {
  const players = [
    { name: 'Alice', cards: [{ rank: CardRank.TWO, suit: CardSuit.HEARTS }], totalScore: 0 }, // 2 pts (menor)
    { name: 'Bob', cards: [{ rank: CardRank.EIGHT, suit: CardSuit.CLUBS }], totalScore: 0 }   // 8 pts
  ];

  const results = calculateRoundScores(players, null, 'DECK_EMPTY');
  const aliceRes = results.find(r => r.name === 'Alice');
  const bobRes = results.find(r => r.name === 'Bob');

  assert.equal(aliceRes.roundScore, 102); // 2 + 100 = 102
  assert.equal(bobRes.roundScore, 8);
});

test('Parity resolution: successful match burns cards', () => {
  const topDiscard = { rank: CardRank.SEVEN, suit: CardSuit.HEARTS, isBurned: false };
  const targetCard = { rank: CardRank.SEVEN, suit: CardSuit.SPADES, isBurned: false };
  const callerHand = [targetCard, { rank: CardRank.ACE, suit: CardSuit.HEARTS }];

  const res = resolveParity({
    topDiscard,
    targetCard,
    caller: 'Alice',
    targetPlayer: 'Alice',
    callerHand,
    targetHand: callerHand,
    deck: []
  });

  assert.equal(res.success, true);
  assert.equal(topDiscard.isBurned, true);
  assert.equal(targetCard.isBurned, true);
  assert.equal(callerHand[0], null); // Carta eliminada
});

test('Parity resolution: failed match gives penalty card', () => {
  const topDiscard = { rank: CardRank.SEVEN, suit: CardSuit.HEARTS, isBurned: false };
  const targetCard = { rank: CardRank.THREE, suit: CardSuit.SPADES, isBurned: false };
  const callerHand = [targetCard];
  const deck = [{ rank: CardRank.KING, suit: CardSuit.HEARTS }];

  const res = resolveParity({
    topDiscard,
    targetCard,
    caller: 'Alice',
    targetPlayer: 'Alice',
    callerHand,
    targetHand: callerHand,
    deck
  });

  assert.equal(res.success, false);
  assert.equal(callerHand.length, 2); // Carta original + penalización
});
