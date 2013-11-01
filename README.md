puppet-moodle
=============

Puppet module for managing moodle

Example:

class { "moodle":
  installdir => "/opt",
  vhostname => "moodle.interlegis.leg.br", 
  serveradmin => "seitadmins@interlegis.leg.br",
  dbhost => 'databasehost.interlegis.leg.br',
  dbuser => 'username',
  dbpass => 'password',
  wwwroot => 'http://moodle.interlegis.leg.br',
}


Class parameters and default values:

$source = "https://github.com/moodle/moodle"  --> Git location of Moodle files
$installdir = "/opt"                          --> Installation folder will be $installdir/moodle
$gitbranch = "MOODLE_25_STABLE"               --> Git branch to use for git clone
$vhostname = $fqdn                            --> Hostname configured in apache server configuration
$serveradmin = "admin@$domain"                --> Admin e-mail to be configured in apache

The following variables are configured inside Moodle's config.php:

$dbtype = 'pgsql'                             --> Database type
$dblibrary = 'native'                         --> Moodle default, don't know what this is for...
$dbhost = false                               --> Database server host, mandatory
$dbname = 'moodle'                            --> Database name
$dbuser = false                               --> Database user name, mandatory
$dbpass = false                               --> Database user password, mandatory
$dbprefix = 'mdl_'                            --> Database prefix
$wwwroot = "http://$fqdn"                     --> URL from which moodle will be accessed
$dataroot = "$installdir/moodledata"          --> Root for moodle data files
$adminusername = 'admin'                      --> Moodle's administrator username


Installing a Moodle mod:

moodle::mod { "certificate":
  source => "https://moodle.org/plugins/download.php/4692/mod_certificate_moodle26_2013102300.zip",
}


Installing a moodle block:

moodle::block { "configurable_reports":
  source => "https://moodle.org/plugins/download.php/2264/block_configurable_reports_moodle25_2011040105.zip",
}


Enjoy!

Fabio Rauber
fabior@interlegis.leg.br
