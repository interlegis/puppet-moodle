#init.pp
## Requires Modules puppetlabs-apache and interlegis/puppet-git

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

	if !$dbhost or !dbuser or !$dbpass {
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
        }
        include apache::mod::php
        
	# Vhost with serveradmin
        apache::vhost { $vhostname:
                port => '80',
                docroot => "$installdir/moodle",
                serveradmin => $serveradmin,
                access_log_file => 'access_moodle.log',
                error_log_file => 'error_moodle.log',
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


}
