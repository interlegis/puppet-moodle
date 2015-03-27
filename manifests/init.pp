#init.pp
## Require Modules puppetlabs/puppetlabs-apache and interlegis/puppet-git

class moodle ( 	$source = "https://github.com/moodle/moodle",
		$installdir = "/opt",
		$gitbranch = "MOODLE_28_STABLE",
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
		$dataroot = "",
		$adminusername = 'admin',
                $reports = {}, 
                $tools = {},
                $enrols = {},
                $blocks = {},
                $mods = {},
                $themes = {},
                $profilefields = {},
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
                        path => ['/usr/local/sbin','/usr/local/bin','/usr/sbin','/usr/bin','/sbin','/bin']
		}

                vcsrepo { "$installdir/moodle":
                	ensure   => present,
			provider => git,
			source   => $source,
			revision => $gitbranch,
		}
	}

	file { "$installdir/moodledata":
		ensure => directory,
		owner => 'www-data', group => 'root', mode => '664',
		require => Vcsrepo["$installdir/moodle"],
	}

	class { 'apache':
                mpm_module => 'prefork',
		keepalive => 'off',
		keepalive_timeout => '4',
		timeout => '45',
                default_vhost => false,
                default_ssl_vhost => false,
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
	$prereqs = [ 'php5-curl', 
                     'php5-pgsql', 
                     'php5-gd', 
                     'php5-xmlrpc', 
                     'php5-intl', 
                     'ghostscript', 
                   ]
        ensure_packages($prereqs)

	file { "$installdir/moodle/config.php":
		owner => 'root', group => 'www-data', mode => '440',
		content => template('moodle/config.php.erb'),
		require => Vcsrepo["$installdir/moodle"],
	}

	# PHP Cache Config
	php::module { [ 'opcache' ]: }
    	php::module::ini { 'opcache':
      		settings => {
                        'zend_extension'                => '/usr/lib/php5/20121212/opcache.so',
                        'opcache.enable'                => '1',
                        'opcache.memory_consumption'    => '512',
                        'opcache.max_accelerated_files' => '4000',
                        'opcache.revalidate_freq'       => '60',
                        'opcache.use_cwd'               => '1',
                        'opcache.validate_timestamps'   => '1',
                        'opcache.save_comments'         => '1',
                        'opcache.enable_file_override'  => '0',
      		}
    	}

	# Moodle Cron
	$cron_i = 5*fqdn_rand(2)
	cron { "admin cron.php":
                command => "/usr/bin/php $installdir/moodle/admin/cli/cron.php",
                minute => [0+$cron_i,10+$cron_i,20+$cron_i,30+$cron_i,40+$cron_i,50+$cron_i],
                ensure => present,
                environment => [
                        "MAILTO=$serveradmin",
                        "SHELL=/bin/bash",
                ],		
		require => Vcsrepo["$installdir/moodle"],
        }

        # Create defines
        validate_hash($reports)
        create_resources(moodle::report,$reports)

        validate_hash($mods)
        create_resources(moodle::mod,$mods)

        validate_hash($blocks)
        create_resources(moodle::block,$blocks)

        validate_hash($enrols)
        create_resources(moodle::enrol,$enrols)
        
        validate_hash($tools)
        create_resources(moodle::tool,$tools)

	validate_hash($themes)
        create_resources(moodle::theme,$themes)
        
	validate_hash($profilefields)
        create_resources(moodle::profilefield,$profilefields)

}
