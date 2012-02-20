require 'capistrano/ext/multistage'

set :stages, %(staging, production)
set :default_stage, 'staging'

set :normalize_asset_timestamps, false

set :repository, "."
set :deploy_via, :copy

set :application, "helloworld"
set :virtual_host, "helloworld"
set :node_file, "app.js"

set :daemon_user, "www-data"
set :daemon_group, "www-data"
set :data_group, "www-data"

set :scm, :git

# uncomment to use nginx
set :http_port, 3000

set :deploy_to, "/opt/nodeapps/#{application}"

namespace :deploy do
  task :start, :roles => :app do
    run "start #{application}"
  end

  task :stop, :roles => :app do
    run "stop #{application}"
  end

  task :write_upstart_script, :roles => :app do
    port = fetch(:http_port, "socket")

    upstart_script = <<-EOF
description "#{application}"

start on startup
stop on shutdown

env NODE_ENV=#{stage}
env PORT=#{port}

script
  set -e
  mkfifo #{deploy_to}/shared/tmp/cronolog
  ( /usr/bin/cronolog #{deploy_to}/shared/log/staging.%Y.%m.%d.log -S #{deploy_to}/shared/log/staging.log < #{deploy_to}/shared/tmp/cronolog & )
  exec > #{deploy_to}/shared/tmp/cronolog 2>&1
  rm #{deploy_to}/shared/tmp/cronolog
  exec start-stop-daemon -c #{daemon_user} -g #{daemon_group} -d #{deploy_to}/shared/tmp -m -p #{deploy_to}/shared/pids/master.pid --startas /usr/bin/node -S -- #{deploy_to}/current/#{node_file}
end script

respawn
EOF

    put upstart_script, "/tmp/#{application}_upstart.conf"
    run "#{try_sudo :as => 'root'} mv /tmp/#{application}_upstart.conf /etc/init/#{application}.conf"
 end

 task :write_nginx_config, :roles => :app do
   if fetch(:http_port, "socket") == "socket"
     nginx_config = <<-EOF

upstream "backend_#{application}" {
  server "unix:#{deploy_to}/shared/tmp/socket";
}

server {
  server_name "#{virtual_host}";
  location / {
    proxy_pass "http://backend_#{application}";
  }
}
EOF

      put nginx_config, "/tmp/#{application}_nginx.config"
      run "#{try_sudo :as => 'root'} mv /tmp/#{application}_nginx.config /etc/nginx/sites-available/#{application}"
      run "#{try_sudo :as => 'root'} ln -sf /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
      run "#{try_sudo :as => 'root'} /etc/init.d/nginx reload"
    end
  end

  task :make_shared_tmp, :roles => :app do
    run "#{try_sudo :as => "root"} mkdir -p #{deploy_to}/shared/tmp"
  end

  task :change_group, :roles => :app do
    run "#{try_sudo :as => "root"} chown :#{data_group} -R #{deploy_to}"
    run "#{try_sudo :as => "root"} chmod g+rws -R #{deploy_to}"
  end

  task :start, :roles => :app do
    run "#{try_sudo :as => "root"} start #{application}"
  end

  task :stop, :roles => :app do
    run "#{try_sudo :as => "root"} stop #{application}"
  end

  task :restart, :roles => :app do
    run "#{try_sudo :as => "root"} start #{application} || #{try_sudo :as => "root"} reload #{application}"
  end

  after 'deploy:setup', 'deploy:make_shared_tmp'
  after 'deploy:setup', 'deploy:change_group'
  after 'deploy:setup', 'deploy:write_upstart_script'
  after 'deploy:setup', 'deploy:write_nginx_config'
end

