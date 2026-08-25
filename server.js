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

  // 2. UNIRSE A UNA SALA
  socket.on('join_room', (data) => {
    const roomCode = data.roomCode;
    const userName = data.userName;

    // ¿Existe la sala en nuestra memoria?
    if (rooms[roomCode]) {
      socket.roomCode = roomCode;
      socket.userName = userName;

      socket.join(roomCode);

      // Sacamos solo los nombres para mandarlos al celular
      const userNames = rooms[roomCode].map(u => u.name);

      // Le mandamos la lista actual de jugadores al que acaba de entrar
      socket.emit('room_joined', { 
          roomCode: roomCode, 
          users: userNames 
      });

      // Lo agregamos a nuestra memoria del servidor
      rooms[roomCode].push({ id: socket.id, name: userName });

      // Le avisamos A LOS DEMÁS (to) que llegó alguien
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