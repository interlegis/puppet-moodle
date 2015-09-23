#profilefield.pp
#Require module camptocamp/puppet-archive

define moodle::profilefield  (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'user/profile/field',
	}
}
