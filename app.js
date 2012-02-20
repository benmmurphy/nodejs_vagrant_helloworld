var ncluster = require('ncluster');
ncluster('./server.js', {workers: 5});
