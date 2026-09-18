const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http, { cors: { origin: '*' } });

const {
  createDeck,
  shuffleDeck,
  canTriggerPower,
  calculateRoundScores,
  resolveParity
} = require('./gameLogic');

// Almacén de salas:
// rooms[roomCode] = {
//   users: [ { id, name, isHost, isReady } ],
//   game: { roundNumber, deck, discardPile, players, activePlayerIndex, drawnCard, drawnFrom, pendingPowerCard }
// }
const rooms = {};

app.get('/', (req, res) => res.send('Servidor Walatro funcionando 🚀'));

function initRound(roomCode, roundNumber = 1) {
  const room = rooms[roomCode];
  if (!room) return;

  const rawDeck = shuffleDeck(createDeck());
  const players = [];

  // 4 cartas para cada jugador
  for (const user of room.users) {
    const hand = [];
    for (let i = 0; i < 4; i++) {
      if (rawDeck.length > 0) {
        hand.push(rawDeck.pop());
      }
    }
    players.push({
      id: user.id,
      name: user.name,
      cards: hand,
      roundScore: 0,
      totalScore: user.totalScore || 0
    });
  }

  // Primera carta del descarte
  const topDiscard = rawDeck.pop();
  topDiscard.isFaceUp = true;

  room.game = {
    roundNumber,
    deck: rawDeck,
    discardPile: [topDiscard],
    players,
    activePlayerIndex: (roundNumber - 1) % players.length,
    drawnCard: null,
    drawnFrom: null,
    pendingPowerCard: null
  };

  // Emitir inicio de ronda a cada jugador con sus cartas en privado (niebla de guerra)
  for (const p of players) {
    const otherPlayers = players
      .filter(other => other.name !== p.name)
      .map(other => ({
        name: other.name,
        cardCount: other.cards.filter(c => c !== null).length
      }));

    io.to(p.id).emit('round_started', {
      roundNumber,
      myHand: p.cards,
      otherPlayers,
      topDiscard,
      deckCount: rawDeck.length,
      peekDurationSeconds: 5
    });
  }

  // Notificar turno inicial
  const activePlayer = players[room.game.activePlayerIndex];
  io.in(roomCode).emit('turn_changed', { activePlayer: activePlayer.name });
}

function advanceTurn(roomCode) {
  const room = rooms[roomCode];
  if (!room || !room.game) return;

  const game = room.game;
  const nextIndex = (game.activePlayerIndex + 1) % game.players.length;
  game.activePlayerIndex = nextIndex;
  const nextPlayer = game.players[nextIndex];

  // Caso 2 de fin de ronda: Si al comenzar su turno el jugador tiene 0 cartas,
  // se activa automáticamente "Soy el que tiene menos cartas"
  const activeCardsCount = nextPlayer.cards.filter(c => c !== null).length;
  if (activeCardsCount === 0) {
    endRound(roomCode, 'ZERO_CARDS', nextPlayer.name);
    return;
  }

  io.in(roomCode).emit('turn_changed', { activePlayer: nextPlayer.name });
}

function endRound(roomCode, reason, callerName) {
  const room = rooms[roomCode];
  if (!room || !room.game) return;

  const game = room.game;
  const results = calculateRoundScores(game.players, callerName, reason);

  // Guardar puntajes totales en users para las siguientes rondas
  for (const res of results) {
    const u = room.users.find(user => user.name === res.name);
    if (u) {
      u.totalScore = res.totalScore;
    }
  }

  io.in(roomCode).emit('round_ended', {
    reason,
    caller: callerName,
    players: results
  });
}

io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);

  // 1. CREAR SALA
  socket.on('create_room', (data) => {
    const userName = data.userName;
    const roomCode = Math.random().toString(36).substring(2, 6).toUpperCase();

    socket.roomCode = roomCode;
    socket.userName = userName;

    const hostPlayer = { id: socket.id, name: userName, isHost: true, isReady: true, totalScore: 0 };
    rooms[roomCode] = {
      users: [hostPlayer],
      game: null
    };

    socket.join(roomCode);
    socket.emit('room_joined', { roomCode, users: rooms[roomCode].users });
  });

  // 2. UNIRSE A SALA
  socket.on('join_room', (data) => {
    const roomCode = data.roomCode;
    const userName = data.userName;

    if (rooms[roomCode]) {
      socket.roomCode = roomCode;
      socket.userName = userName;
      socket.join(roomCode);

      const guestPlayer = { id: socket.id, name: userName, isHost: false, isReady: false, totalScore: 0 };
      rooms[roomCode].users.push(guestPlayer);

      socket.emit('room_joined', { roomCode, users: rooms[roomCode].users });
      socket.to(roomCode).emit('user_joined', guestPlayer);
    } else {
      socket.emit('error', 'La sala no existe o está vacía.');
    }
  });

  // 3. SET READY
  socket.on('set_ready', (data) => {
    const room = rooms[data.roomCode];
    if (room) {
      const player = room.users.find(p => p.name === data.userName);
      if (player && !player.isHost) {
        player.isReady = data.isReady;
        io.in(data.roomCode).emit('ready_changed', { userName: data.userName, isReady: data.isReady });
      }
    }
  });

  // 4. INICIAR PARTIDA
  socket.on('start_game', (roomCode) => {
    const room = rooms[roomCode];
    if (room) {
      io.in(roomCode).emit('game_started');
      // Breve margen (120ms) para que los clientes naveguen y monten listeners
      setTimeout(() => {
        initRound(roomCode, 1);
      }, 120);
    }
  });

  // Re-sincronizar estado si un cliente entró tarde o perdió el evento
  socket.on('get_game_state', (data) => {
    const { roomCode, playerName } = data;
    const room = rooms[roomCode];
    if (room && room.game) {
      const game = room.game;
      const player = game.players.find(p => p.name === playerName);
      if (player) {
        const otherPlayers = game.players
          .filter(other => other.name !== player.name)
          .map(other => ({
            name: other.name,
            cardCount: other.cards.filter(c => c !== null).length
          }));
        const topDiscard = game.discardPile[game.discardPile.length - 1];

        socket.emit('round_started', {
          roundNumber: game.roundNumber,
          myHand: player.cards,
          otherPlayers,
          topDiscard,
          deckCount: game.deck.length,
          peekDurationSeconds: 5
        });

        const activePlayer = game.players[game.activePlayerIndex];
        if (activePlayer) {
          socket.emit('turn_changed', { activePlayer: activePlayer.name });
        }
      }
    }
  });

  // 5. CHAT Y ACCIONES GENÉRICAS
  socket.on('send_chat', (data) => {
    io.in(data.roomCode).emit('chat_message', { senderName: data.senderName, message: data.message });
  });

  socket.on('game_action', (data) => {
    io.in(data.roomCode).emit('game_action', data);
  });

  // ==========================================
  // EVENTOS DEL JUEGO WALATRO
  // ==========================================

  // 6. ROBAR CARTA (draw_card)
  socket.on('draw_card', (data) => {
    const { roomCode, from, playerName } = data;
    const room = rooms[roomCode];
    if (!room || !room.game) return;

    const game = room.game;
    const activePlayer = game.players[game.activePlayerIndex];
    if (!activePlayer || activePlayer.name !== playerName) return;

    let drawnCard = null;

    if (from === 'discard') {
      const topDiscard = game.discardPile[game.discardPile.length - 1];
      // Regla estricta: No se puede robar si la carta fue quemada en paridad
      if (!topDiscard || topDiscard.isBurned) {
        socket.emit('error', 'No puedes robar del descarte: la carta fue quemada en paridad.');
        return;
      }
      drawnCard = game.discardPile.pop();
      drawnCard.isFromDiscard = true;
    } else {
      // Caso 3 de fin de ronda: Mazo agotado
      if (game.deck.length === 0) {
        endRound(roomCode, 'DECK_EMPTY', null);
        return;
      }
      drawnCard = game.deck.pop();
    }

    drawnCard.isFaceUp = true;
    game.drawnCard = drawnCard;
    game.drawnFrom = from;

    // Al que robó se le envía la carta completa; a los demás se les oculta si fue del mazo
    socket.emit('card_drawn', { playerName, from, card: drawnCard });
    socket.to(roomCode).emit('card_drawn', {
      playerName,
      from,
      card: from === 'discard' ? drawnCard : null
    });
  });

  // 7. JUGAR CARTA ROBADA (play_drawn_card)
  socket.on('play_drawn_card', (data) => {
    const { roomCode, action, targetSlotIndex, playerName } = data;
    const room = rooms[roomCode];
    if (!room || !room.game || !room.game.drawnCard) return;

    const game = room.game;
    const activePlayer = game.players[game.activePlayerIndex];
    if (!activePlayer || activePlayer.name !== playerName) return;

    let discardedCard = null;

    if (action === 'SWAP' && targetSlotIndex !== undefined && targetSlotIndex !== null) {
      if (targetSlotIndex >= 0 && targetSlotIndex < activePlayer.cards.length) {
        discardedCard = activePlayer.cards[targetSlotIndex];
        const newCard = game.drawnCard;
        newCard.isFaceUp = false;
        activePlayer.cards[targetSlotIndex] = newCard;
        // Notificar mano actualizada al jugador
        socket.emit('hand_updated', { myHand: activePlayer.cards });
      }
    } else {
      // DISCARD directo
      discardedCard = game.drawnCard;
    }

    game.drawnCard = null;

    if (!discardedCard) return;

    discardedCard.isFaceUp = true;
    game.discardPile.push(discardedCard);

    const powerAvailable = canTriggerPower(discardedCard);

    io.in(roomCode).emit('card_discarded', {
      playerName,
      card: discardedCard,
      replacedSlot: targetSlotIndex,
      powerAvailable
    });

    if (powerAvailable) {
      game.pendingPowerCard = discardedCard;
      // Se espera a use_power o skip_power
    } else {
      advanceTurn(roomCode);
    }
  });

  // 8. USAR PODER (use_power)
  socket.on('use_power', (data) => {
    const { roomCode, powerType, mySlot, targetPlayer, targetSlot, playerName } = data;
    const room = rooms[roomCode];
    if (!room || !room.game) return;

    const game = room.game;
    const powerCard = game.pendingPowerCard;
    if (powerCard) {
      powerCard.powerUsed = true;
    }

    if (powerType === 'PEEK_OWN' && mySlot !== undefined) {
      const player = game.players.find(p => p.name === playerName);
      if (player && player.cards[mySlot]) {
        socket.emit('private_peek_result', {
          card: player.cards[mySlot],
          targetPlayer: playerName,
          slotIndex: mySlot
        });
      }
    } else if (powerType === 'PEEK_OTHER' && targetPlayer && targetSlot !== undefined) {
      const target = game.players.find(p => p.name === targetPlayer);
      if (target && target.cards[targetSlot]) {
        socket.emit('private_peek_result', {
          card: target.cards[targetSlot],
          targetPlayer,
          slotIndex: targetSlot
        });
      }
    } else if (powerType === 'SWAP' && mySlot !== undefined && targetPlayer && targetSlot !== undefined) {
      const player = game.players.find(p => p.name === playerName);
      const target = game.players.find(p => p.name === targetPlayer);
      if (player && target) {
        const myCard = player.cards[mySlot];
        const targetCard = target.cards[targetSlot];
        player.cards[mySlot] = targetCard;
        target.cards[targetSlot] = myCard;

        // Notificar manos actualizadas a ambos jugadores
        io.to(player.id).emit('hand_updated', { myHand: player.cards });
        io.to(target.id).emit('hand_updated', { myHand: target.cards });
      }
    }

    if (powerCard) {
      io.in(roomCode).emit('power_activated', {
        user: playerName,
        card: powerCard,
        powerType
      });
    }

    game.pendingPowerCard = null;
    advanceTurn(roomCode);
  });

  // 9. SALTAR PODER (skip_power)
  socket.on('skip_power', (data) => {
    const { roomCode } = data;
    const room = rooms[roomCode];
    if (room && room.game) {
      room.game.pendingPowerCard = null;
      advanceTurn(roomCode);
    }
  });

  // 10. RECLAMAR PARIDAD (claim_parity)
  socket.on('claim_parity', (data) => {
    const { roomCode, caller, targetPlayer, slotIndex } = data;
    const room = rooms[roomCode];
    if (!room || !room.game) return;

    const game = room.game;
    const topDiscard = game.discardPile[game.discardPile.length - 1];
    if (!topDiscard || topDiscard.isBurned) return;

    const callerPlayer = game.players.find(p => p.name === caller);
    const target = game.players.find(p => p.name === targetPlayer);
    if (!callerPlayer || !target || !target.cards[slotIndex]) return;

    const targetCard = target.cards[slotIndex];

    const result = resolveParity({
      topDiscard,
      targetCard,
      caller,
      targetPlayer,
      callerHand: callerPlayer.cards,
      targetHand: target.cards,
      deck: game.deck
    });

    if (result.error) return;

    io.in(roomCode).emit('parity_resolved', {
      caller,
      targetPlayer,
      slotIndex,
      success: result.success,
      cardPlayed: result.cardPlayed,
      penaltyCard: result.penaltyCard || null
    });

    if (result.success) {
      io.in(roomCode).emit('card_burned', {
        card: result.burnedCard,
        burnedBy: caller
      });
    }

    // Sincronizar manos privadas de los afectados y conteos
    if (callerPlayer) {
      io.to(callerPlayer.id).emit('hand_updated', { myHand: callerPlayer.cards });
    }
    if (target && target.id !== callerPlayer.id) {
      io.to(target.id).emit('hand_updated', { myHand: target.cards });
    }

    io.in(roomCode).emit('player_counts_updated', {
      players: game.players.map(p => ({
        name: p.name,
        cardCount: p.cards.filter(c => c !== null).length
      }))
    });
  });

  // 11. CANTAR MENOR (call_lowest)
  socket.on('call_lowest', (data) => {
    const { roomCode, playerName } = data;
    endRound(roomCode, 'CALLED_LOW', playerName);
  });

  // 12. SIGUIENTE RONDA (next_round)
  socket.on('next_round', (data) => {
    const { roomCode } = data;
    const room = rooms[roomCode];
    if (room && room.game) {
      initRound(roomCode, room.game.roundNumber + 1);
    }
  });

  // 13. DESCONEXIÓN
  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
    if (socket.roomCode && rooms[socket.roomCode]) {
      rooms[socket.roomCode].users = rooms[socket.roomCode].users.filter(u => u.id !== socket.id);
      socket.to(socket.roomCode).emit('user_left', { userName: socket.userName });
      if (rooms[socket.roomCode].users.length === 0) {
        delete rooms[socket.roomCode];
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  http.listen(PORT, '0.0.0.0', () => console.log(`Servidor Walatro en puerto ${PORT} 🚀`));
}

module.exports = { app, http, io, rooms };