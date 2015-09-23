#theme.pp
#Require module camptocamp/puppet-archive

define moodle::theme (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'theme',
	}
}
