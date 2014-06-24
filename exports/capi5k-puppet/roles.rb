# where puppet will be installed
def role_puppet
  $myxp.get_deployed_nodes('bootstrap') + 
  $myxp.get_deployed_nodes('groupmanager') + 
  $myxp.get_deployed_nodes('localcontroller') + 
  $myxp.get_deployed_nodes('cassandra') 
end

# puppet version to use (env var)
def puppet_version
  "PUPPET_VERSION=2.7.19"
end

