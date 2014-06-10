#tool.pp
#Require module camptocamp/puppet-archive

define moodle::tool (	$source = false,
		) {

	moodle::addon { "$name":
		source => $source,
		destfolder => 'admin/tool',
	}
}
