set :application, 'thunder'
set :repo_url, 'git@github.com:zhangyuan/thunder_search.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :user, 'deploy'
set :use_sudo, false

set :deploy_to, "/home/#{fetch :user}/apps/#{fetch :application}"
set :scm, :git

set :format, :pretty
set :log_level, :debug
set :pty, true

set :linked_files, %w{
  config/settings.local.yml config/database.yml config/unicorn.rb 
  config/unicorn_init config/nginx.conf
}

set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :default_env, { path: "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH" }
set :keep_releases, 5

remote_file "config/settings.local.yml" => "config/settings.local.yml.example"
remote_file "config/database.yml" => "config/database.yml.example"
remote_file "config/unicorn.rb" => "config/unicorn.rb.example"
remote_file "config/unicorn_init" => "config/unicorn_init.example"
remote_file "config/nginx.conf" => "config/nginx.conf.example"

namespace :deploy do
  namespace :check do
    task :linked_files => fetch(:linked_files)
  end

  desc "precompile asseets and sync to web server"
  task :assets_sync do
    system('bundle exec rake assets:precompile')

    on roles(:web) do |server|
      system "rsync -vr --exclude='.DS_Store' public/assets #{fetch :user}@#{server}:#{release_path}/public/"
    end
    system('rm -rf public/assets')
  end

  desc "rake db:migrate"
  task :db_migrate do
    on roles(:db) do
      execute "cd #{release_path} && bundle exec rake db:migrate RAILS_ENV=production"
    end
  end

  after 'deploy:updated', 'deploy:db_migrate'
  after 'deploy:updated', 'deploy:assets_sync'

  desc "Start application"
  task :start do
    on roles(:app) do
      execute "cd #{deploy_to}/current && bundle exec unicorn_rails -c config/unicorn.rb -E production -D"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s USR2 `cat #{deploy_to}/current/tmp/pids/unicorn.pid`"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s QUIT `cat #{deploy_to}/current/tmp/pids/unicorn.pid`"
    end
  end

  after :finishing, 'deploy:cleanup'
end
