# cassandra nodes
def role_cassandra
  $myxp.get_deployed_nodes('cassandra')
end

# seeds
def seeds_cassandra
  $myxp.get_deployed_nodes('cassandra').slice(0..4) 
end

# expose recipe
def file_cassandra_recipe
  "#{cassandra_path}/templates/cassandra.erb"
end

