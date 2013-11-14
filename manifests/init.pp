#init.pp
## Require Modules puppetlabs/puppetlabs-apache and interlegis/puppet-git

class moodle ( 	$source = "https://github.com/moodle/moodle",
		$installdir = "/opt",
		$gitbranch = "MOODLE_25_STABLE",
		$vhostname = $fqdn,
		$serveradmin = "admin@$domain",
		$dbtype = 'pgsql',
		$dblibrary = 'native',
		$dbhost = false,
		$dbname = 'moodle',
		$dbuser = false,
		$dbpass = false,
		$dbprefix = 'mdl_',
		$wwwroot = "http://$fqdn",
		$dataroot = "$installdir/moodledata",
		$adminusername = 'admin',
	) {

	if !$dbhost or !$dbuser or !$dbpass {
		fail("The following variables are mandatory: dbhost, dbuser, dbpass")
	}

	if $source == false {
		package { "moodle": ensure => present }
	} else {
		## Puppet does not support recursively created directories, so mkdir -p...
		exec { "create installdir":
			command => "mkdir -p $installdir",
			unless => "test -d $installdir",
		}

		git::clone { "moodle":
                	source => $source,
                	localtree => "$installdir",
			branch => $gitbranch,
			require => Exec["create installdir"],
        	}
	}

	file { "$installdir/moodledata":
		ensure => directory,
		owner => 'www-data', group => 'root', mode => '664',
		require => Git::Clone["moodle"],
	}

	class { 'apache':
                mpm_module => 'prefork',
		keepalive => 'off',
		keepalive_timeout => '4',
		timeout => '45',
        }
        include apache::mod::php
	include apache::mod::expires
        
	# Vhost with serveradmin
        apache::vhost { $vhostname:
                port => '80',
                docroot => "$installdir/moodle",
                serveradmin => $serveradmin,
                access_log_file => 'access_moodle.log',
                error_log_file => 'error_moodle.log',
		options => ['Indexes','FollowSymLinks'],
		custom_fragment => '<IfModule mod_expires.c>
                        ExpiresActive On
                        ExpiresDefault "access plus 1 seconds"
                        ExpiresByType text/html "access plus 1 seconds"
                        ExpiresByType image/gif "access plus 1 week"
                        ExpiresByType image/jpeg "access plus 1 week"
                        ExpiresByType image/png "access plus 1 week"
                        ExpiresByType text/css "access plus 1 week"
                        ExpiresByType text/javascript "access plus 1 week"
                        ExpiresByType application/x-javascript "access plus 1 week"
                        ExpiresByType text/xml "access plus 1 seconds"
                </IfModule> ',
        }

	# Install package requirements
	$prereqs = [ "php5-curl", "php5-pgsql", "php5-gd", "php5-xmlrpc", "php5-intl" ]
  	define pkgpreq {
    		if !defined(Package[$title]) {
      			package { $title: ensure => present; }
		}
    	}
  	pkgpreq {$prereqs: }

	file { "$installdir/moodle/config.php":
		owner => 'root', group => 'www-data', mode => '440',
		content => template('moodle/config.php.erb'),
		require => Git::Clone["moodle"],
	}

	# PHP Cache Config
	php::module { [ 'apc' ]: }
    	php::module::ini { 'apc':
      		settings => {
        		'apc.enabled'      => '1',
        		'apc.shm_segments' => '1',
        		'apc.shm_size'     => '128M',
			'apc.stat'	   => '0',	
      		}
    	}

	# Moodle Cron
	$cron_i = 5*fqdn_rand(2)
	cron { "admin cron.php":
                command => "/usr/bin/php $installdir/moodle/admin/cron.php",
                minute => [0+$cron_i,10+$cron_i,20+$cron_i,30+$cron_i,40+$cron_i,50+$cron_i],
                ensure => present,
                environment => [
                        "MAILTO=$serveradmin",
                        "SHELL=/bin/bash",
                ],
                require => Git::Clone["moodle"],
        }

}
