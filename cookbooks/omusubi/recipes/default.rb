execute "apt-get" do
  command "apt-get update"
end

packages = %w{git subversion nginx php5 php5-mysql php5-curl php5-cli php5-fpm php-pear mysql-server curl imagemagick php5-imagick}

packages.each do |pkg|
  package pkg do
    action [:install, :upgrade]
    version node.default[:versions][pkg]
  end
end

execute "phpunit-install" do
  command "pear config-set auto_discover 1; pear install pear.phpunit.de/PHPUnit"
  not_if { ::File.exists?("/usr/bin/phpunit")}
end

execute "composer-install" do
  command "curl -sS https://getcomposer.org/installer | php ;mv composer.phar /usr/local/bin/composer"
  not_if { ::File.exists?("/usr/local/bin/composer")}
end

template "/etc/nginx/conf.d/php-fpm.conf" do
  mode 0644
  source "php-fpm.conf.erb"
end

# service 'apache2' do
#   action :stop
# end

%w{mysql php5-fpm nginx}.each do |service_name|
    service service_name do
      action [:start, :restart]
    end
end

mysql_connection_info = {
  :host => "localhost",
  :username => 'root'
  # :password => node['mysql']['server_root_password']
}

# create a mysql user but grant no privileges
mysql_database_user node['mysql']['server_root_username'] do
  connection mysql_connection_info
  password node['mysql']['server_root_password']
  action :create
end

# grant all privileges on all databases/tables from localhost
mysql_database_user node['mysql']['server_root_username'] do
  connection mysql_connection_info
  password node['mysql']['server_root_password']
  action :grant
end