const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.emit('welcome', 'Connected to {{PROJECT_NAME}}!');
});

server.listen(4000, () => console.log('Socket.io listening on :4000'));
