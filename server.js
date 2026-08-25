const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http, { cors: { origin: '*' } });

const rooms = {};

app.get('/', (req, res) => res.send('Servidor Celestina funcionando 🚀'));

io.on('connection', (socket) => {
  console.log('Alguien se conectó:', socket.id);

  socket.on('create_room', (data) => {
    const userName = data.userName;
    const roomCode = Math.random().toString(36).substring(2, 6).toUpperCase();

    socket.roomCode = roomCode;
    socket.userName = userName;

    // El creador SIEMPRE es host y SIEMPRE está ready
    const newPlayer = { id: socket.id, name: userName, isHost: true, isReady: true };
    rooms[roomCode] = [newPlayer];

    socket.join(roomCode);
    socket.emit('room_joined', { roomCode: roomCode, users: rooms[roomCode] });
  });

  socket.on('join_room', (data) => {
    const roomCode = data.roomCode;
    const userName = data.userName;

    if (rooms[roomCode]) {
      socket.roomCode = roomCode;
      socket.userName = userName;
      socket.join(roomCode);

      // Los invitados empiezan sin estar listos
      const newPlayer = { id: socket.id, name: userName, isHost: false, isReady: false };
      rooms[roomCode].push(newPlayer);

      socket.emit('room_joined', { roomCode: roomCode, users: rooms[roomCode] });
      socket.to(roomCode).emit('user_joined', newPlayer);
    } else {
      socket.emit('error', 'La sala no existe o está vacía.');
    }
  });

  // --- NUEVO: Manejo de Ready ---
  socket.on('set_ready', (data) => {
    const room = rooms[data.roomCode];
    if (room) {
      const player = room.find(p => p.name === data.userName);
      // Evitamos que el dueño se quite el ready
      if (player && !player.isHost) {
        player.isReady = data.isReady;
        io.in(data.roomCode).emit('ready_changed', { userName: data.userName, isReady: data.isReady });
      }
    }
  });

  // --- NUEVO: Empezar el juego ---
  socket.on('start_game', (roomCode) => {
    io.in(roomCode).emit('game_started');
  });

  socket.on('send_chat', (data) => {
    io.in(data.roomCode).emit('chat_message', { senderName: data.senderName, message: data.message });
  });

  socket.on('game_action', (data) => io.in(data.roomCode).emit('game_action', data));

  socket.on('disconnect', () => {
    if (socket.roomCode && rooms[socket.roomCode]) {
      rooms[socket.roomCode] = rooms[socket.roomCode].filter(u => u.id !== socket.id);
      socket.to(socket.roomCode).emit('user_left', { userName: socket.userName });
      if (rooms[socket.roomCode].length === 0) {
        delete rooms[socket.roomCode];
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
http.listen(PORT, '0.0.0.0', () => console.log(`Servidor en puerto ${PORT} 🚀`));