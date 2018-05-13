set :use_sudo, false
set :repo_url,  "/home/deployer/git/tipcalc.git"
set :deploy_to, '/home/deployer/projects/tipcalc'
set :rails_env, "production"
set :linked_dirs, %w{ log tmp/pids tmp/cache }
set :linked_files, %w{ config/application.yml }
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"
set :rvm_ruby_string, '2.1.5@tipcalc'
set :deploy_via, :remote_cache

server('deployer@192.241.188.86',
  user: 'deployer',
  password: fetch(:password),
  roles: %w{web app db},
  ssh_options: {
    keys: %w( ~/.ssh/id_rsa.tc_second_mbp_deployer /home/vekozlov/.ssh/id_rsa.tm_do_test_deployer ),
    forward_agent: false,
      auth_methods: %w(publickey)
  }
)

# =================================
# Unicorn Server
# =================================

namespace :deploy do
  desc 'Restart application on server'
  task :restart do
    on roles(:app) do
      info "=========== RESTARTING UNICORN =========="
      execute "ps aux | grep 'unicorn' | awk '{print $2}' | xargs kill -9"
      execute "cd /home/deployer/projects/tipcalc/current && /usr/local/rvm/bin/rvm use 2.1.5 do bundle exec unicorn -c /home/deployer/projects/tipcalc/current/config/unicorn.rb -E production -D"
    end
  end

  desc 'Move 404 and 500 pages to public folder'
  task :move_error_pages do
    on roles(:app) do
      info "=========== MOVING 404 and 500 pages =========="
      execute "cd /home/deployer/projects/tipcalc/current && /usr/local/rvm/bin/rvm use 2.1.5 do bundle exec rake move_error_pages"
    end
  end
end

# =================================
# Deploy Callbacks
# =================================

namespace :deploy do
  after :finishing, :restart
  after :finishing, :move_error_pages
end

desc "Clear cache on server"
namespace :config do
  task :clear_cache, :folder_path do |task, args|
    on roles(:app) do
      info "=========== Clearing cache =========="
      execute "rm -rf /home/deployer/projects/tipcalc/shared/tmp/cache/*"
    end
  end
end

# restoring data to test data

# scp -r ~/Downloads/home/deployer/projects/tipcalc/shared/2017_08_20-00_00_08.production/tipcalc_production/ deployer@192.241.188.86:/home/deployer/db/backups/2017_08_20-00_00_08.production/
# cd ~/projects/tipcalc/current && RAILS_ENV=production rvm use 2.1.5 do bundle exec rake db:purge
# scp -r local_folder deployer@192.241.188.86:/home/deployer/db/backups/2017_08_20-00_00_08.production/
# mongorestore -h localhost:27017 -d tipcalc_production ~/db/backups/2017_08_20-00_00_08.production/tipcalc_production