Example of using ncluster with capistrano.

# Running

    cap deploy:setup
    cap deploy

    curl -v http://localhost:3000

# Running behind Nginx
   cap staging_nginx deploy:setup
   cap staging_nginx deploy

   add 127.0.0.1 helloworld to /etc/hosts
   curl -v http://helloworld

# Similar Tools

* roco (https://github.com/1602/roco)
