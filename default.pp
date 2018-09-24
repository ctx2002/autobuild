Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ]}

exec { 'apt-get update':
  command => 'apt-get update',
  timeout => 60,
  tries   => 3
}

include stdlib
include apt

$greeting = "Hello world\n";
$myos = $facts['os']['distro']['description'];
notify { 'greeting':
    message => "Setup development machine on ${myos}, puppet version is ${clientversion}"
}

package { 'zip':
  ensure => present,
}

package { 'unzip':
  ensure => present,
}

package { 'supervisor':
  ensure => present
}

exec{ 'copy supervisor industry':
  cwd         => '/vagrant/local.ranqx.io',
  user        => 'root',
  command     => 'cp /vagrant/puppet/environments/develop/data/industry.conf /etc/supervisor/conf.d/industry.conf'
}->
exec{ 'copy supervisor fin alert':
  cwd         => '/vagrant/local.ranqx.io',
  user        => 'root',
  command     => 'cp /vagrant/puppet/environments/develop/data/fin_alert.conf /etc/supervisor/conf.d/fin_alert.conf',
  notify => Service['supervisord']
}

service { 'supervisord':
    ensure => running,
	enable => true
}

file { 'my test file':
    ensure => present,
	path => '/tmp/hello',
    content => "${greeting}"
}

package { 'puppet':
    name => 'puppet',
	ensure => present
}

package { 'vim':
    name => 'vim',
	ensure => present
}

package { ['software-properties-common']:
  ensure  => 'installed',
  require => Exec['apt-get update'],
}

$sysPackages = [ 'build-essential', 'git', 'curl','libcurl4-openssl-dev', 'pkg-config', 'libssl-dev', 'libpcre3-dev']
package { $sysPackages:
  ensure => "installed",
  require => Exec['apt-get update'],
}

class { 'nginx': }

class { '::mysql::server':
  root_password           => 'root',
}

class {'::mongodb::server':
  port    => 27017,
  verbose => true,
}

class { '::mongodb::client': }
class { 'elastic_stack::repo':
  version => 5,
}

class { 'java':
  distribution => 'jre',
}->
class { 'elasticsearch': 
   version => '5.6.4',
   ensure => 'present',
   restart_on_change => true,
   jvm_options => [
    '-Xms4g',
    '-Xmx4g'
  ]
}

elasticsearch::instance { 'esranqx': }

class { '::php::globals':
  php_version => '7.2',
  config_root => '/etc/php/7.2',
}->
class { 'nodejs': 
    manage_package_repo       => false,
    nodejs_dev_package_ensure => 'present',
    npm_package_ensure        => 'present',
}->
exec { 'update_apt_key':
        command => 'echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list',
        onlyif  => "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -",
}->
exec { 'install yarn':
    command => 'apt-get update && apt-get install --no-install-recommends yarn',
    user => 'root'	
}->
class { '::php':
	manage_repos => true,
	settings   => {
		'PHP/max_execution_time'  => '90',
		'PHP/max_input_time'      => '300',
		'PHP/memory_limit'        => '256M',
		'PHP/post_max_size'       => '32M',
		'PHP/upload_max_filesize' => '32M',
		'Date/date.timezone'      => 'Pacific/Auckland',
	},
	extensions => {
        'bcmath' => {},
        'gd'	 => {},
		'mysql'  => {
		    'multifile_settings' => true,
			'settings' => {
			  'mysqli' => { },
			  'mysqlnd' => { },
			  'pdo_mysql' => { }
			}
		},
        'mongodb' => {},
        'oauth'     => {},
        'mbstring'  => {},
        'curl' => {},
        'gmp'  => {}		
	}
}->
exec { 'run composer':
  environment => ["COMPOSER_HOME=/home/vagrant", "SYMFONY__path_to_node=/usr/bin/node", 
                  "SYMFONY__path_to_node_modules=/usr/lib/node_modules",
                      "SYMFONY__database_password=root"],
  cwd         => '/vagrant/local.ranqx.io',
  user        => 'vagrant',
  command     => 'composer install -vvv --no-interaction || /bin/true',
  timeout     => 3600,
  logoutput   => true,
}
->
exec { 'install encore':
    cwd         => '/vagrant/local.ranqx.io',
    user        => 'vagrant',
    command     => '/usr/bin/yarn add --dev @symfony/webpack-encore'
}->
exec { 'yarn install':
    cwd         => '/vagrant/local.ranqx.io',
    user        => 'vagrant',
    command     => '/usr/bin/yarn install'
}
->
exec { 'run yarn':
      cwd         => '/vagrant/local.ranqx.io',
      user        => 'vagrant',
      command     => '/usr/bin/yarn run encore dev'
}


$full_web_path = '/vagrant/'

define web::nginx_php_vhost (
  $php                  = true,
  $proxy                = undef,
  $www_root             = "${full_web_path}/${name}/web/",
  $location_cfg_append  = undef,
) {
  nginx::resource::server { "${name}":
    ensure                => present,
    listen_port           => 80,
    use_default_location => false,
    www_root              => $www_root,
    owner                  => 'vagrant',
    group                  => 'vagrant',
    access_log            => "/var/log/nginx/${name}_access.log",
    error_log             => "/var/log/nginx/${name}_error.log",
    index_files => []
  }
  

  if $php {
    
    nginx::resource::location { "${name}_root":
      server           => "${name}",
      ensure          => present,
      location        => '/',
      index_files => [],
      location_custom_cfg => {
        try_files => '$uri @rewriteapp',
        index => 'app_dev.php'
      }
    }
    
    nginx::resource::location { "${name}_root_2":
      server           => "${name}",
      ensure          => present,
      location        => '@rewriteapp',
      location_custom_cfg => {
        rewrite => '^(.*)$ /app_dev.php/$1 last'
      },
      index_files => []
    }
    
    nginx::resource::location { "${name}_root_1":
      server           => "${name}",
      ensure          => present,
      location        => '~ \.php(/|$)',
      fastcgi         => "unix:/var/run/php5-fpm.sock",
      fastcgi_script  => undef,
      index_files => [],
      location_custom_cfg => {
        fastcgi_split_path_info => '^(.+\.php)(/.+)$',
        fastcgi_buffers => '32 512k',
        fastcgi_buffer_size =>  '512k',
        fastcgi_param => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
        fastcgi_read_timeout => '600',
      }
    }
  }
}

web::nginx_php_vhost { "local.ranqx.io":
  www_root => "/vagrant/local.ranqx.io/web",
}

exec{ 'copy dev':
  cwd         => '/vagrant/local.ranqx.io',
  user        => 'vagrant',
  command     => 'cp /vagrant/local.ranqx.io/web_default/app_dev.php /vagrant/local.ranqx.io/web/app_dev.php'
}->
exec{ 'copy para':
  cwd         => '/vagrant/local.ranqx.io',
  user        => 'vagrant',
  command     => 'cp /vagrant/puppet/environments/develop/data/parameters.yml /vagrant/local.ranqx.io/app/config/parameters.yml',
}






