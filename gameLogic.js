// ==========================================
// WALATRO GAME LOGIC MODULE
// ==========================================

const CardSuit = {
  SPADES: 'spades',
  HEARTS: 'hearts',
  DIAMONDS: 'diamonds',
  CLUBS: 'clubs',
  JOKER: 'joker'
};

const CardRank = {
  ACE: 'ace',
  TWO: 'two',
  THREE: 'three',
  FOUR: 'four',
  FIVE: 'five',
  SIX: 'six',
  SEVEN: 'seven',
  EIGHT: 'eight',
  NINE: 'nine',
  TEN: 'ten',
  JACK: 'jack',
  QUEEN: 'queen',
  KING: 'king',
  JOKER: 'joker'
};

/**
 * Retorna el valor en puntos de una carta según las reglas de Walatro:
 * - Joker: 0 puntos
 * - K de Picas (K♠): -1 punto
 * - As: 1 punto
 * - 2 al 10: 2 a 10 puntos
 * - J, Q, K (resto): 10 puntos
 */
function getCardScoreValue(card) {
  if (!card) return 0;
  if (card.rank === CardRank.JOKER) return 0;
  if (card.rank === CardRank.KING && card.suit === CardSuit.SPADES) return -1;

  switch (card.rank) {
    case CardRank.ACE: return 1;
    case CardRank.TWO: return 2;
    case CardRank.THREE: return 3;
    case CardRank.FOUR: return 4;
    case CardRank.FIVE: return 5;
    case CardRank.SIX: return 6;
    case CardRank.SEVEN: return 7;
    case CardRank.EIGHT: return 8;
    case CardRank.NINE: return 9;
    case CardRank.TEN:
    case CardRank.JACK:
    case CardRank.QUEEN:
    case CardRank.KING:
      return 10;
    default:
      return 0;
  }
}

/**
 * Crea una baraja completa de 54 cartas inglesas (52 estándar + 2 Jokers)
 */
function createDeck() {
  const deck = [];
  let idCounter = 1;
  const suits = [CardSuit.SPADES, CardSuit.HEARTS, CardSuit.DIAMONDS, CardSuit.CLUBS];
  const ranks = [
    CardRank.ACE, CardRank.TWO, CardRank.THREE, CardRank.FOUR, CardRank.FIVE,
    CardRank.SIX, CardRank.SEVEN, CardRank.EIGHT, CardRank.NINE, CardRank.TEN,
    CardRank.JACK, CardRank.QUEEN, CardRank.KING
  ];

  for (const suit of suits) {
    for (const rank of ranks) {
      deck.push({
        id: `card_${idCounter++}_${suit}_${rank}`,
        suit,
        rank,
        isFaceUp: false,
        isBurned: false,
        powerUsed: false,
        isFromDiscard: false
      });
    }
  }

  // 2 Jokers
  deck.push({
    id: `card_${idCounter++}_joker_1`,
    suit: CardSuit.JOKER,
    rank: CardRank.JOKER,
    isFaceUp: false,
    isBurned: false,
    powerUsed: false,
    isFromDiscard: false
  });
  deck.push({
    id: `card_${idCounter++}_joker_2`,
    suit: CardSuit.JOKER,
    rank: CardRank.JOKER,
    isFaceUp: false,
    isBurned: false,
    powerUsed: false,
    isFromDiscard: false
  });

  return deck;
}

/**
 * Barajado Fisher-Yates
 */
function shuffleDeck(deck) {
  const shuffled = [...deck];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * Verifica si una carta puede activar poder (7, 8 o 9)
 */
function canTriggerPower(card) {
  if (!card) return false;
  const isPowerRank = card.rank === CardRank.SEVEN ||
                      card.rank === CardRank.EIGHT ||
                      card.rank === CardRank.NINE;
  return isPowerRank && !card.powerUsed && !card.isBurned && !card.isFromDiscard;
}

/**
 * Suma de puntos de la mano de un jugador
 */
function calculatePlayerCardsSum(cards) {
  let sum = 0;
  for (const c of cards) {
    if (c) {
      sum += getCardScoreValue(c);
    }
  }
  return sum;
}

/**
 * Calcula y aplica los resultados de fin de ronda según las reglas:
 * - Caso 1 (CALLED_LOW):
 *   - Si el que cantó tiene estrictamente la menor suma: suma - 10
 *   - Si no o si hay empate: suma + 30
 *   - Resto: sus sumas normales
 * - Caso 2 (ZERO_CARDS): Mismas reglas que el caso 1 para el jugador de 0 cartas
 * - Caso 3 (DECK_EMPTY): El de menor suma recibe penalización +100 puntos
 */
function calculateRoundScores(players, callerName, reason) {
  const results = [];
  const playerSums = [];

  for (const p of players) {
    const sum = calculatePlayerCardsSum(p.cards || []);
    playerSums.push({ name: p.name, sum, player: p });
  }

  const minSum = Math.min(...playerSums.map(ps => ps.sum));
  const minCount = playerSums.filter(ps => ps.sum === minSum).length;

  for (const ps of playerSums) {
    let roundScore = ps.sum;

    if (reason === 'CALLED_LOW' || reason === 'ZERO_CARDS') {
      if (ps.name === callerName) {
        // Estrictamente menor sin empates
        if (ps.sum === minSum && minCount === 1) {
          roundScore = ps.sum - 10;
        } else {
          roundScore = ps.sum + 30;
        }
      }
    } else if (reason === 'DECK_EMPTY') {
      if (ps.sum === minSum) {
        roundScore = ps.sum + 100;
      }
    }

    const currentTotal = ps.player.totalScore || 0;
    const newTotal = currentTotal + roundScore;
    ps.player.roundScore = roundScore;
    ps.player.totalScore = newTotal;

    // Asegurar que todas las cartas queden reveladas para el resumen
    const revealedCards = (ps.player.cards || []).map(c => c ? { ...c, isFaceUp: true } : null);

    results.push({
      name: ps.name,
      cards: revealedCards,
      roundScore,
      totalScore: newTotal
    });
  }

  return results;
}

/**
 * Resuelve un intento de paridad
 */
function resolveParity({ topDiscard, targetCard, caller, targetPlayer, callerHand, targetHand, deck }) {
  if (!topDiscard || topDiscard.isBurned) {
    return { error: 'No hay carta válida en el descarte para paridad' };
  }
  if (!targetCard) {
    return { error: 'No hay carta objetivo en esa posición' };
  }

  const isMatch = targetCard.rank === topDiscard.rank;
  const isMine = caller === targetPlayer;

  if (isMatch) {
    // Éxito: ambas cartas se queman
    targetCard.isBurned = true;
    topDiscard.isBurned = true;

    if (isMine) {
      // El jugador pierde la carta (1 carta menos)
      const slotIndex = targetHand.indexOf(targetCard);
      if (slotIndex !== -1) targetHand[slotIndex] = null;
    } else {
      // Quema la carta del rival y le entrega una propia
      const targetSlot = targetHand.indexOf(targetCard);
      if (targetSlot !== -1) targetHand[targetSlot] = null;

      // El llamador da una de sus cartas al rival
      const myCardIndex = callerHand.findIndex(c => c !== null);
      if (myCardIndex !== -1) {
        const myCard = callerHand[myCardIndex];
        callerHand[myCardIndex] = null;
        targetHand[targetSlot] = myCard;
      }
    }

    return {
      success: true,
      cardPlayed: targetCard,
      burnedCard: targetCard
    };
  } else {
    // Fallo de paridad
    if (isMine) {
      // Conserva su carta y recibe carta de penalización (+1 carta)
      let penaltyCard = null;
      if (deck && deck.length > 0) {
        penaltyCard = deck.pop();
        penaltyCard.isFaceUp = false;
        callerHand.push(penaltyCard);
      }
      return {
        success: false,
        cardPlayed: targetCard,
        penaltyCard
      };
    } else {
      // Se queda con la carta del rival + penalización (rival queda con 1 carta menos, llamador recibe 2)
      const targetSlot = targetHand.indexOf(targetCard);
      if (targetSlot !== -1) targetHand[targetSlot] = null;

      targetCard.isFaceUp = false;
      callerHand.push(targetCard);

      let penaltyCard = null;
      if (deck && deck.length > 0) {
        penaltyCard = deck.pop();
        penaltyCard.isFaceUp = false;
        callerHand.push(penaltyCard);
      }

      return {
        success: false,
        cardPlayed: targetCard,
        penaltyCard
      };
    }
  }
}

module.exports = {
  CardSuit,
  CardRank,
  getCardScoreValue,
  createDeck,
  shuffleDeck,
  canTriggerPower,
  calculatePlayerCardsSum,
  calculateRoundScores,
  resolveParity
};
