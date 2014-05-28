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
    type                                 => "localcontroller",
    groupManagerHeartbeatPort            => $groupManagerHeartbeatPort,
    zookeeperHosts                       => ["econome-1.nantes.grid5000.fr"],
    virtualMachineSubnet                 => ["10.176.0.0/22"],
    externalNotificationHost             => "econome-1.nantes.grid5000.fr",
    databaseCassandraHosts               => ["econome-18.nantes.grid5000.fr"],
    imageRepositorySource                => "/tmp/snooze/images",
    imageRepositoryDestination           => "/tmp/images",
}







