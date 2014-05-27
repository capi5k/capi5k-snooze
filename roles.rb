role :bootstrap do
  $myxp.get_deployed_nodes('bootstrap').first
end

role :first_bootstrap do
  $myxp.get_deployed_nodes('bootstrap').first
end

role :groupmanager do
  $myxp.get_deployed_nodes('groupmanager')
end

role :localcontroller do
  $myxp.get_deployed_nodes('localcontroller')
end

role :webinterface do
  $myxp.get_deployed_nodes('bootstrap')
end


role :frontend do
  "#{site}"
end

role :subnet do
  "#{site}"
end


role :all do
  $myxp.get_deployed_nodes('bootstrap') + $myxp.get_deployed_nodes('groupmanager') +  $myxp.get_deployed_nodes('localcontroller')  
end

def zookeeperHosts
  $myxp.get_deployed_nodes('bootstrap').first
end

def zookeeperdHosts
  $myxp.get_deployed_nodes('bootstrap').first
end

def rabbitmqServer
  $myxp.get_deployed_nodes('bootstrap').first
end

def cassandraHosts
  $myxp.get_deployed_nodes('cassandra')
end

