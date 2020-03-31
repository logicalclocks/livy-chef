name             "livy"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2"
description      'Installs/Configures Livy Server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.0"
source_url       "https://github.com/hopshadoop/livy-chef"


depends "java", '~> 7.0.0'
depends 'kagent'
depends 'hops'
depends 'ndb'
depends 'hadoop_spark'
depends 'conda'

recipe           "install", "Installs a Livy Spark REST Server"
recipe           "default", "Starts  a Livy Spark REST Server"
recipe           "purge", "Removes and deletes an installed Livy Spark REST Server"

attribute "livy/user",
          :description => "User to install/run as",
          :type => 'string'

attribute "livy/group",
          :description => "Group to install/run as",
          :type => 'string'

attribute "livy/dir",
          :description => "base dir for installation",
          :type => 'string'

attribute "livy/version",
          :dscription => "livy version",
          :type => "string"

attribute "livy/url",
          :dscription => "livy url to binary",
          :type => "string"

attribute "livy/port",
          :dscription => "livy port",
          :type => "string"

attribute "livy/home",
          :dscription => "livy home directory",
          :type => "string"

attribute "livy/keystore",
          :dscription => "ivy keystore path",
          :type => "string"

attribute "livy/keystore_password",
          :dscription => "ivy keystore_password",
          :type => "string"

attribute "livy/default/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"

attribute "livy/log",
          :dscription => "Path to livy log-file from log4j",
          :type => "string"

attribute "livy/log_size",
          :dscription => "Max size of logfile. Default: '20MB' ",
          :type => "string"

attribute "livy/rsc/rpc/max/size",
          :dscription => "Max size of rpc. Default: '256MB' ",
          :type => "string"

attribute "livy/rpc/max/size",
          :dscription => "Max size of rpc. Default: '256MB' ",
          :type => "string"

