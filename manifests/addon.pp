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
                vcsrepo { "${moodle::installdir}/moodle/$destfolder/$name":
                        ensure   => present,
                        provider => git,
                        source   => $source,
                        require  => Vcsrepo["${moodle::installdir}/moodle"],
                }
	} else {	
		archive { $name:
			ensure => present,
			url    => $source,
			target => "${moodle::installdir}/moodle/$destfolder",
			checksum => false,
			extension => inline_template("<%= source.rpartition('.')[2] %>"),
			require => [ Package['unzip'],
                                     Vcsrepo["${moodle::installdir}/moodle"]
                                   ],
		}
	}	
}
