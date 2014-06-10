#report.pp
#Require module camptocamp/puppet-archive

define moodle::report (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'report',
	}
}
