#block.pp
#Require module camptocamp/puppet-archive

define moodle::block (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'blocks',
	}
}
