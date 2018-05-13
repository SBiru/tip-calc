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

server('deployer@192.241.181.99',
  user: 'deployer',
  password: fetch(:password),
  roles: %w{web app db},
  ssh_options: {
    keys: %w( /Users/vekozlov/.ssh/id_rsa.do_tipcalc_deployer /home/vekozlov/.ssh/id_rsa.tm_ipad_deployer ),
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

desc "Backup dp to sample folder"
namespace :db do
  task :backup_to_local do |task, args|
    folder_name = Time.now.strftime("%Y.%m.%d-%H.%M.%S")

    on roles(:app) do
      info "=========== Removing old base =========="
      execute "mongodump --host 127.0.0.1:27017 --db tipcalc_production --username tipcalc_db_user --password tipcalc_db_password --out ~/db/backups/#{ folder_name }"
    end
    `scp -r deployer@192.241.181.99:~/db/backups/#{ folder_name } ./tmp/db/#{ folder_name }`
    `RAILS_ENV="development" rake db:purge`
    `mongorestore -h localhost:27017 -d tipcalc_development ./tmp/db/#{ folder_name }/tipcalc_production`
  end
end

# mongorestore -h localhost:27017 -d tipcalc_development ./tmp/db/2017.06.13-13.08.22/tipcalc_production
