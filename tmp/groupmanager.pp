include "kadeploy3"
include "snoozeclient"

$groupManagerHeartbeatPort = 1000+$idfromhost

#
# Specific deployment are automatically generated, 
# To change other parameters (schedulers ...) go to templates/snooze_node.erb.$version
#

class { 
'snoozenode':
    version                              => "2",
    type                                 => "groupmanager",
    groupManagerHeartbeatPort            => $groupManagerHeartbeatPort,
    zookeeperHosts                       => ["pastel-34.toulouse.grid5000.fr"],
    virtualMachineSubnet                 => ["10.160.0.0/22"],
    externalNotificationHost             => "pastel-34.toulouse.grid5000.fr",
    databaseCassandraHosts               => ["pastel-52.toulouse.grid5000.fr"],
    imageRepositorySource                => "/tmp/snooze/images",
    imageRepositoryDestination           => "/tmp/images",
}







