set :deploy_to, "/path/to/project" # Example: /var/www/myproject

server 'SERVER NAME/IP', user: 'USERNAME', roles: %w{web app db}