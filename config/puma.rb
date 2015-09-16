current_path = "/home/deployer/api-server/current"
shared_path = "/home/deployer/api-server/shared"
 
bind "unix://#{shared_path}/sockets/puma.sock"
pidfile "#{shared_path}/tmp/puma/pid"
state_path "#{shared_path}/tmp/puma/state"
rackup "#{current_path}/config.ru"
 
threads 4, 8
 
activate_control_app