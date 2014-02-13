#mod.pp
#Require module camptocamp/puppet-archive

define moodle::enrol (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'enrol',
	}
}
