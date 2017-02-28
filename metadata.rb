name             "livy"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2"
description      'Installs/Configures Livy Server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"
source_url       "https://github.com/hopshadoop/livy-chef"



depends          "hadoop_spark"
depends          "ndb"
depends          "hops"
depends          "kagent"
depends          "java"

recipe           "install", "Installs a Livy Spark REST Server"
recipe           "default", "Starts  a Livy Spark REST Server"
recipe           "purge", "Removes and deletes an installed Livy Spark REST Server"

attribute "java/jdk_version",
          :description =>  "Jdk version",
          :type => 'string'

attribute "java/install_flavor",
          :description =>  "Oracle (default) or openjdk",
          :type => 'string'

attribute "livy/user",
          :description => "User to install/run as",
          :type => 'string'

attribute "livy/dir",
          :description => "base dir for installation",
          :type => 'string'

attribute "livy/version",
          :dscription => "livy.version",
          :type => "string"

attribute "livy/url",
          :dscription => "livy.url",
          :type => "string"

attribute "livy/port",
          :dscription => "livy.port",
          :type => "string"

attribute "livy/home",
          :dscription => "livy.home",
          :type => "string"

attribute "livy/keystore",
          :dscription => "ivy.keystore",
          :type => "string"

attribute "livy/keystore_password",
          :dscription => "ivy.keystore_password",
          :type => "string"

attribute "livy/default/private_ips",
          :description => "Set ip addresses",
          :type => "array"

