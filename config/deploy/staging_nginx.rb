role :app, "default"
set :service_name, "helloworld_nginx"
set :deploy_to, "/opt/nodeapps/helloworld_nginx"
set :virtual_host, "#{application}"
