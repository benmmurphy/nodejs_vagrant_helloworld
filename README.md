Example of using ncluster with capistrano.

# Dependencies
## Capistrano
## Nodejs Vagrant

    gem install vagrant

    git clone git://github.com/benmmurphy/nodejs_vagrant.git
    cd nodejs_vagrant

    vagrant box add vagrant-oneiric https://github.com/downloads/benmmurphy/nodejs_vagrant/package_4.1.8.box
    vagrant up
    vagrant ssh-config >> ~/.ssh/config
    ssh default #to check ssh is working

# Running

    git clone git://github.com/benmmurphy/nodejs_vagrant_helloworld.git
    cd nodejs_vagrant_helloworld
    cap deploy:setup
    cap deploy
    
    ssh default
    curl -v http://localhost:3000

# Running behind Nginx

    cap staging_nginx deploy:setup
    cap staging_nginx deploy
    
    ssh default
    << add 127.0.0.1 helloworld to /etc/hosts >>
    curl -v http://helloworld

# Similar Tools

* roco (https://github.com/1602/roco)
