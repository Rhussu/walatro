const test = require('node:test');
const assert = require('node:assert/strict');
const ioClient = require('socket.io-client');
const { http } = require('../server');

function createClient(port) {
  return ioClient(`http://localhost:${port}`, {
    transports: ['websocket'],
    forceNew: true
  });
}

test('Socket.IO Server E2E Flow: Room Creation, Game Start, and Turn Draw', async (t) => {
  const port = await new Promise((resolve) => {
    const server = http.listen(0, '127.0.0.1', () => {
      resolve(server.address().port);
    });
  });

  t.after(() => {
    http.close();
  });

  const client1 = createClient(port);
  const client2 = createClient(port);

  t.after(() => {
    client1.disconnect();
    client2.disconnect();
  });

  let roomCode = null;

  // 1. Client 1 crea sala
  await new Promise((resolve) => {
    client1.on('room_joined', (data) => {
      assert.ok(data.roomCode);
      assert.equal(data.users.length, 1);
      assert.equal(data.users[0].name, 'Player1');
      assert.equal(data.users[0].isHost, true);
      roomCode = data.roomCode;
      resolve();
    });
    client1.emit('create_room', { userName: 'Player1' });
  });

  // 2. Client 2 se une a la sala
  await new Promise((resolve) => {
    client1.on('user_joined', (user) => {
      assert.equal(user.name, 'Player2');
      assert.equal(user.isHost, false);
      resolve();
    });
    client2.emit('join_room', { roomCode, userName: 'Player2' });
  });

  // 3. Iniciar juego
  let p1Hand = null;
  let p2Hand = null;

  await new Promise((resolve) => {
    let count = 0;
    client1.on('round_started', (data) => {
      assert.equal(data.roundNumber, 1);
      assert.equal(data.myHand.length, 4);
      assert.equal(data.otherPlayers.length, 1);
      assert.equal(data.otherPlayers[0].cardCount, 4);
      assert.ok(data.topDiscard);
      p1Hand = data.myHand;
      count++;
      if (count === 2) resolve();
    });

    client2.on('round_started', (data) => {
      assert.equal(data.roundNumber, 1);
      assert.equal(data.myHand.length, 4);
      assert.equal(data.otherPlayers.length, 1);
      assert.equal(data.otherPlayers[0].cardCount, 4);
      p2Hand = data.myHand;
      count++;
      if (count === 2) resolve();
    });

    client1.emit('start_game', roomCode);
  });

  assert.ok(p1Hand);
  assert.ok(p2Hand);

  // 4. Robar carta (Player 1 tiene el turno)
  await new Promise((resolve) => {
    client1.on('card_drawn', (data) => {
      assert.equal(data.playerName, 'Player1');
      assert.equal(data.from, 'deck');
      assert.ok(data.card); // Player 1 ve su carta
      resolve();
    });

    client2.on('card_drawn', (data) => {
      assert.equal(data.playerName, 'Player1');
      assert.equal(data.card, null); // Player 2 NO ve la carta robada del mazo
    });

    client1.emit('draw_card', { roomCode, from: 'deck', playerName: 'Player1' });
  });

  // 5. Jugar la carta (SWAP con posición 0)
  await new Promise((resolve) => {
    client1.on('card_discarded', (data) => {
      assert.equal(data.playerName, 'Player1');
      assert.ok(data.card);
      assert.equal(data.replacedSlot, 0);
      resolve();
    });

    client1.emit('play_drawn_card', {
      roomCode,
      action: 'SWAP',
      targetSlotIndex: 0,
      playerName: 'Player1'
    });
  });
});
