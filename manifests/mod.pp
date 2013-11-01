#mod.pp
#Require module camptocamp/puppet-archive

define moodle::mod (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'mod',
	}
}
