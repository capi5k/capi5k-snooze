def role_nfs_server
  $myxp.get_deployed_nodes('bootstrap').first 
end

def role_nfs_slave
  $myxp.get_deployed_nodes('localcontroller')
end

def nfs_exported
    "/tmp/snooze"
end

def nfs_local_mounted
    "/tmp/snooze"
end

def uid
  "snoozeadmin"
end

def gid
  "snooze"
end


def nfs_options
  "rw,nfsvers=3,hard,intr,async,noatime,nodev,nosuid,auto,rsize=32768,wsize=32768"
end
