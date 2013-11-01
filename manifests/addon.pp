#addon.pp
#Require module camptocamp/puppet-archive and interlegis/puppet-git

define moodle::addon (	$source = false,
			$destfolder = 'mod',
		) {
	if !$source {
		fail("Source variable required!")
	}
	if ! defined(Class["moodle"]) {
		fail("Class moodle must be defined first!.")
	}

	if ! defined(Package['unzip']) {
		package { 'unzip': ensure => 'present' }
	}

	if ' ' in $name {
		fail("Addon name must not contain spaces.")
	}	

	if '.git' in $source {
		git::clone { $name:
                	source => $source,
                	localtree => "${moodle::installdir}/moodle/$destfolder",
        	}	
	} else {	
		archive { $name:
			ensure => present,
			url    => $source,
			target => "${moodle::installdir}/moodle/$destfolder",
			checksum => false,
			extension => inline_template("<%= source.rpartition('.')[2] %>"),
			require => Package['unzip'],
		}
	}	
}
