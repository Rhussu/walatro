const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http, {
  cors: {
    origin: '*'
  }
});

// Memoria rápida para saber quién está en qué sala
// Se verá algo así: { "XQYZ": [ { id: "123", name: "Walter" } ] }
const rooms = {};

app.get('/', (req, res) => {
  res.send('Servidor Celestina funcionando 🚀');
});

io.on('connection', (socket) => {
  console.log('Alguien se conectó:', socket.id);

  // 1. CREAR SALA
  socket.on('create_room', (data) => {
    const userName = data.userName;
    const roomCode = Math.random().toString(36).substring(2, 6).toUpperCase();

    // Guardamos los datos en el socket mismo, es un buen truco para cuando se desconecten
    socket.roomCode = roomCode;
    socket.userName = userName;

    // Inicializamos la sala en nuestra memoria
    rooms[roomCode] = [ { id: socket.id, name: userName } ];

    socket.join(roomCode);

    // Le respondemos AL CREADOR con el evento que Flutter espera
    socket.emit('room_joined', { 
        roomCode: roomCode, 
        users: [userName] 
    });

    console.log(`Sala creada: ${roomCode} por ${userName}`);
  });

  // 4. ACCIONES DEL JUEGO (Ready, Movimientos, Estados)
  socket.on('game_action', (data) => {
    // io.in manda la data a todos en la sala (incluyendo al que lo envió, 
    // así todos sincronizan el mismo estado)
    io.in(data.roomCode).emit('game_action', data);
  });

  socket.on('join_room', (data) => {
      const roomCode = data.roomCode;
      const userName = data.userName;

      if (rooms[roomCode]) {
        socket.roomCode = roomCode;
        socket.userName = userName;
        socket.join(roomCode);

        // 1. PRIMERO te agregamos a la memoria del servidor
        rooms[roomCode].push({ id: socket.id, name: userName });

        // 2. AHORA SÍ sacamos la lista de nombres (contigo incluido)
        const userNames = rooms[roomCode].map(u => u.name);

        // 3. Te enviamos la lista completa
        socket.emit('room_joined', { 
            roomCode: roomCode, 
            users: userNames 
        });

        // Le avisamos a los demás que llegaste
        socket.to(roomCode).emit('user_joined', { userName: userName });

        console.log(`${userName} se unió a ${roomCode}`);
      } else {
        socket.emit('error', 'La sala no existe o está vacía, revisa el código bro.');
      }
    });

  // 3. EL CHAT
  socket.on('send_chat', (data) => {
    // io.in() envía el mensaje a TODOS en la sala, incluyéndote a ti.
    // Así todos ven el mensaje al mismo tiempo.
    io.in(data.roomCode).emit('chat_message', {
        senderName: data.senderName,
        message: data.message
    });
  });

  // 4. CUANDO ALGUIEN CIERRA LA APP O SE LE CAE EL INTERNET
  socket.on('disconnect', () => {
    if (socket.roomCode && rooms[socket.roomCode]) {
        // Lo borramos de la memoria
        rooms[socket.roomCode] = rooms[socket.roomCode].filter(u => u.id !== socket.id);
        
        // Le avisamos al resto que se fue
        socket.to(socket.roomCode).emit('user_left', { userName: socket.userName });
        
        // Si la sala quedó pelada, la borramos para no consumir RAM a lo tonto
        if (rooms[socket.roomCode].length === 0) {
            delete rooms[socket.roomCode];
            console.log(`Sala ${socket.roomCode} eliminada por inactividad.`);
        }
    }
    console.log('Alguien se desconectó:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;

http.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor Celestina corriendo en puerto ${PORT} 🚀`);
});