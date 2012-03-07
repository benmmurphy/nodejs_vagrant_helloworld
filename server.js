var http = require('http');
var express = require('express');
var port = process.env.PORT == null ? 3000 : parseInt(process.env.PORT);
var logger;
if (isNaN(port)) {
  port = process.env.PORT;
  logger = express.logger(':req[x-forwarded-for] - - [:date] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent"');
} else {
  logger = express.logger();
}


var server = express.createServer(logger);

server.listen(port);

server.get('/', function(req, res){
  res.send('Hello World from: ' + process.pid);
});

module.exports = server;

