const express = require('express');
const app = express();
const http = require('http').Server(app);

const io = require('socket.io')(http, {
  cors: {
    origin: '*'
  }
});

// Ruta para comprobar que el servidor está funcionando
app.get('/', (req, res) => {
  res.send('Servidor Celestina funcionando 🚀');
});

io.on('connection', (socket) => {
  console.log('Alguien se conectó:', socket.id);

  socket.on('create_room', () => {
    const roomCode = Math.random()
      .toString(36)
      .substring(2, 6)
      .toUpperCase();

    socket.join(roomCode);

    socket.emit('room_created', roomCode);

    console.log(`Sala creada: ${roomCode}`);
  });

  socket.on('join_room', (roomCode) => {
    const room = io.sockets.adapter.rooms.get(roomCode);

    if (room && room.size > 0) {
      socket.join(roomCode);

      socket.emit('joined');

      socket.to(roomCode).emit('peer_joined');
    } else {
      socket.emit(
        'error',
        'La sala no existe o está vacía, revisa el código bro.'
      );
    }
  });

  socket.on('signal', (data) => {
    socket.to(data.room).emit('signal', data.payload);
  });
});

const PORT = process.env.PORT || 3000;

http.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor Celestina corriendo en puerto ${PORT} 🚀`);
});