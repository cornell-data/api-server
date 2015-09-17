require "bundler/capistrano"

set :application, "api-server"
set :repository,  "git@github.com:cornell-data/api-server.git"

set :use_sudo, false
set(:run_method) { use_sudo ? :sudo : :run }

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

default_run_options[:shell] = '/bin/bash --login'

set :user, "deployer"
set :group, user
set :runner, user

set :host, "#{user}@greenburg.cornelldata.org" # We need to be able to SSH to that box as this user.
role :web, host
role :app, host

set :deploy_to, "/home/#{user}/#{application}"
set :puma_conf, "#{deploy_to}/current/config/puma.rb"
set :puma_pid, "#{deploy_to}/shared/tmp/puma/pid"

namespace :deploy do
  task :restart do
    run "if [ -f #{puma_pid} ]; then kill -USR2 `cat #{puma_pid}`; else cd #{deploy_to}/current && bundle exec puma --config #{puma_conf} --daemon; fi"
  end
  task :start do
    run "cd #{deploy_to}/current && bundle exec puma --config #{puma_conf} --daemon"
  end
  task :stop do
    run "if [ -f #{puma_pid} ]; then kill -QUIT `cat #{puma_pid}`; fi"
  end
end