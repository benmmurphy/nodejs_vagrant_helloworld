require 'capistrano/ext/multistage'

set :stages, %(staging, production)
set :default_stage, 'staging'

set :normalize_asset_timestamps, false

set :repository, "."
set :deploy_via, :copy

set :application, "helloworld"
set :virtual_host, "#{application}"

set :node_file, "app.js"

set :daemon_user, "www-data"
set :daemon_group, "www-data"
set :data_group, "www-data"

set :scm, :git

# uncomment to use nginx
set :http_port, 3000

set :syslog_tag, "#{application}"
set :deploy_to, "/opt/nodeapps/#{application}"

namespace :deploy do

  def put_file(contents, target)
    put contents, "#{deploy_to}/shared/tmp/new_file"
    run "#{try_sudo :as => 'root'} chown root:root #{deploy_to}/shared/tmp/new_file"
    run "#{try_sudo :as => 'root'} mv #{deploy_to}/shared/tmp/new_file #{target}"
  end

  task :start, :roles => :app do
    run "#{try_sudo :as => 'root'} start #{application}"
  end

  task :stop, :roles => :app do
    run "#{try_sudo :as => 'root'} stop #{application}"
  end

  task :write_upstart_script, :roles => :app do
    port = fetch(:http_port, "socket")

    template = File.read(File.join(File.dirname(__FILE__), "deploy", "templates", "upstart.conf.erb"))

    upstart_script = ERB.new(template).result(binding)
    put_file upstart_script, "/etc/init/#{application}.conf"
  end

  task :write_syslog_script, :roles => :app do

    template = File.read(File.join(File.dirname(__FILE__), "deploy", "templates", "syslog.conf.erb"))

    syslog_script = ERB.new(template).result(binding)

    put_file syslog_script, "/etc/rsyslog.d/20-#{application}.conf"   
    run "#{try_sudo :as => 'root'} restart rsyslog"
  end

  task :write_logrotate_conf, :roles => :app do

    template = File.read(File.join(File.dirname(__FILE__), "deploy", "templates", "logrotate.conf.erb"))

    logrotate_conf = ERB.new(template).result(binding)
    put_file logrotate_conf, "/etc/logrotate.d/#{application}"
    run "#{try_sudo :as => 'root'} restart rsyslog"
  end



  task :write_nginx_config, :roles => :app do
    if fetch(:http_port, "socket") == "socket"
      template = File.read(File.join(File.dirname(__FILE__), "deploy", "templates", "nginx.conf.erb"))

      nginx_config = ERB.new(template).result(binding)


      put_file nginx_config, "/etc/nginx/sites-available/#{application}"
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
    cmd = "STATUS=`#{try_sudo :as => 'root'} status #{application}`; echo Previous Status: $STATUS; RESULT=`#{try_sudo :as => 'root'} start #{application} 2>&1`; if [[ $? -eq 0 ]]; then echo $RESULT; else echo Reloading; #{try_sudo :as => 'root'} reload #{application}; fi"

    run cmd, :shell => "/bin/bash"
  end

  task :npm_install, :roles => :app do
    run "cd #{release_path} && npm install"
  end

  after 'deploy:setup', 'deploy:make_shared_tmp'
  after 'deploy:setup', 'deploy:change_group'
  after 'deploy:setup', 'deploy:write_upstart_script'
  after 'deploy:setup', 'deploy:write_syslog_script'
  after 'deploy:setup', 'deploy:write_logrotate_conf'
  after 'deploy:setup', 'deploy:write_nginx_config'

  after "deploy:update_code", "deploy:npm_install"
end

