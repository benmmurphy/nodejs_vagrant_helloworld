var http = require('http');
var express = require('express');

var port = process.env.PORT == null ? 3000 : parseInt(process.env.PORT);
if (isNaN(port)) {
  port = process.env.PORT;
}

var server = express.createServer(
    express.logger(':req[x-forwarded-for] - - [:date] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent"')
);

server.on("close", function() {
  process.exit(0);
});

server.on("listening", function() {
  process.send("ncluster:ready");
});

process.on("SIGQUIT", function() {
  server.close();
});

server.listen(port);

server.get('/', function(req, res){
  res.send('Hello World from: ' + process.pid);
});

