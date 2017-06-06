# config valid only for Capistrano 3.8.1
lock '3.8.1'

set :stages, ["production"] # Stages for your application. Stages defined here should be files inside deploy folder
set :default_stage, "production"
set :ssh_options, {:forward_agent => true}

set :application, 'YOUR APP NAME'
set :scm, :git
set :repo_url, 'git@YOUR GIT REPO'
set :user, "YOUR USERNAME" # Example: root
set :keep_releases, 3

# Set shared files and folders. These will be fetched from current release and place it inside shared folder
# After deploying first time, place .env file from your local project to shared folder in the server
# Then uncomment .env line below. Make all necessary changes and deploy again.

# set :linked_files, %w{.env}
set :linked_dirs, %w{storage}

namespace :vendor do
    desc 'Copy vendor directory from last release'
    task :copy do
        on roles(:web) do
            puts ("Copy vendor folder from previous release")
            execute "vendorDir=#{current_path}/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir #{release_path}/vendor; fi;"
        end
    end
end

namespace :composer do
    desc "Running Composer Install"
    task :install do
        on roles(:app), in: :sequence, wait: 5 do
            within release_path  do
                execute :composer, "install --no-dev"
            end
        end
    end
end

namespace :laravel do

    # Create storage folder for the first deploy in shared folder. 
    # From next deploy remove this task (create_storage_folder) from deploy do

    desc "Create shared folders"
    task :create_storage_folder do
        on roles(:all) do
            execute "mkdir -p #{shared_path}/storage"
            execute "mkdir -p #{shared_path}/storage/app"
            execute "mkdir -p #{shared_path}/storage/framework"
            execute "mkdir -p #{shared_path}/storage/framework/cache"
            execute "mkdir -p #{shared_path}/storage/framework/sessions"
            execute "mkdir -p #{shared_path}/storage/framework/views"
            execute "mkdir -p #{shared_path}/storage/logs"
            execute :chmod, "-R 777 #{shared_path}/storage"
        end
    end

    desc "Setup Laravel folder permissions"
    task :permissions do
        on roles(:app), in: :sequence, wait: 2 do
            within release_path  do
                execute :chmod, "u+x artisan"
                execute :chmod, "-R 777 storage"
                execute :chmod, "-R 777 bootstrap/cache"
            end
        end
    end

# Comment the lines below for the first deploy. Place .env inside shared folder, then remove the comments

     desc "Run Laravel Artisan migrate task."
     task :migrate do
         on roles(:app), in: :sequence, wait: 5 do
             within release_path  do
                 execute :php, "artisan migrate"
             end
         end
    end

# Comment the lines below for the first deploy. Place .env inside shared folder, then remove the comments

    desc "Run Laravel Artisan seed task."
    task :seed do
         on roles(:app), in: :sequence, wait: 5 do
             within release_path  do
                 execute :php, "artisan db:seed"
             end
         end
    end

    desc "Optimize Laravel Class Loader"
    task :optimize do
        on roles(:app), in: :sequence, wait: 5 do
            within release_path  do
                execute :php, "artisan clear-compiled"
                execute :php, "artisan optimize"
            end
        end
    end

end

namespace :deploy do

    after :updated, "vendor:copy"
    after :updated, "laravel:create_storage_folder" # Remove this line after first deploy
    after :published, "composer:install"
    after :published, "laravel:permissions"
    after :published, "laravel:optimize"
    after :published, "laravel:migrate"
    after :published, "laravel:seed"

end