def role_rabbitmq
  $myxp.get_deployed_nodes('bootstrap').first
end

def file_rabbitmq_manifest 
  "#{rabbitmq_path}/templates/rabbitmq.erb"
end


