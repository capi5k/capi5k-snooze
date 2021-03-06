# change accordingly to your project
#
#
#
#
set :proxy, "https_proxy=http://proxy:3128 http_proxy=http://proxy:3128"
set :wget, "https_proxy=http://proxy:3128 http_proxy=http://proxy:3128 wget"
set :git, "https_proxy=http://proxy:3128 http_proxy=http://proxy:3128 git"

set :snooze_puppet_path, "/home/#{g5k_user}/snooze-puppet"
set :snooze_puppet_repo_url, "https://github.com/msimonin/snooze-puppet.git"
set :snooze_experiments_repo_url, "https://github.com/snoozesoftware/snooze-experiments"

set :snooze_path, "./"
set :snooze_deploy_localcluster_url, "https://github.com/snoozesoftware/snooze-deploy-localcluster"
set :snooze_deploy_localcluster_local_path, "/tmp/snooze-deploy-localcluster"
set :snooze_imagesrepository_local_path, "/tmp/snooze/images"

load "#{snooze_path}/roles.rb"
load "#{snooze_path}/roles_definition.rb"
load "#{snooze_path}/output.rb"

load "#{snooze_path}/config.rb"

require 'yaml'

before :snooze, :puppet
namespace :snooze do

  namespace :custom do

    task :default do
      fix_locales
      init
      prepare
      dispatch
      start
    end

    # fix the locales (work around)
    task :fix_locales, :roles => [:all] do
      set :user, "root"
      # enable fr locales
      run 'sed -ie "s/^# *\(fr_FR.*\)/\1/g" /etc/locale.gen && locale-gen'
    end

    desc "Create custom topology file see #{recipes_path}/tmp/topology"
    task :init do
      topology = {}

      groupmanagers = find_servers :roles => [:groupmanager]
      groupmanagers.each do |groupmanager|
        topology[groupmanager.host] = {
          :bootstraps => "0",
          :groupmanagers => "1", 
          :localcontrollers => "0",
        }
      end

      localcontrollers = find_servers :roles => [:localcontroller]
      localcontrollers.each do |localcontroller|
        topology[localcontroller.host] = {
          :bootstraps => "0",
          :localcontrollers => "1",
          :groupmanagers => "0",
        }
      end
      File.open("#{snooze_path}/tmp/topology.yml", 'w') {|f| f.write topology.to_yaml } #Store
    end

    task :prepare, :roles => [:groupmanager, :localcontroller] do
      set :user, "root"
      run "apt-get install -y git"
      run "#{git} clone #{snooze_deploy_localcluster_url} #{snooze_deploy_localcluster_local_path}" 
    end

    task :dispatch do
      set :user, "root"
      servers = find_servers :roles => [:groupmanager, :localcontroller]
      topology = YAML::load_file("#{snooze_path}/tmp/topology.yml") 
      settings = "#{snooze_deploy_localcluster_local_path}/scripts/settings.sh"

      mcast=10000
      servers.each do |s|
        # replace in scripts/settings.sh
        gms = topology[s.host][:groupmanagers]
        lcs = topology[s.host][:localcontrollers]

        run "perl -pi -e 's,^number_of_group_managers.*,number_of_group_managers=#{gms},' #{settings}", :hosts => s
        run "perl -pi -e 's,^number_of_local_controllers.*,number_of_local_controllers=#{lcs},' #{settings}", :hosts => s
        run "perl -pi -e 's,^number_of_bootstrap_nodes.*,number_of_bootstrap_nodes=0,' #{settings}", :hosts => s, :user => "root"
        run "perl -pi -e 's,^start_group_manager_heartbeat_mcast_port.*,start_group_manager_heartbeat_mcast_port=#{mcast},' #{settings}", :hosts => s
        run "perl -pi -e 's,^snoozeimages_enable.*,snoozeimages_enable=false,' #{settings}", :hosts => s
        run "perl -pi -e 's,^snoozeec2_enable.*,snoozeec2_enable=false,' #{settings}", :hosts => s
        # increment the mcast port
        mcast = mcast + gms.to_i + 1
      end
    end

    desc 'Start the custom topology cluster'
    task :start, :roles =>[:bootstrap, :groupmanager, :localcontroller] do
      set :user, "root"
      parallel do |session|
        session.when "in?(:bootstrap)", "service snoozenode start; service snoozeimages start; service snoozeec2 start"
        session.when "in?(:localcontroller)", "cd #{snooze_deploy_localcluster_local_path}; ./start_local_cluster.sh -l 1> log 2>&1 ; ./start_local_cluster.sh -s 1> log 2>&1"
        session.when "in?(:groupmanager)", "cd #{snooze_deploy_localcluster_local_path}; ./start_local_cluster.sh -s 1> log 2>&1"
      end
    end

    desc 'Stop the custom topology cluster'
    task :stop, :roles => [:bootstrap, :groupmanager, :localcontroller] do
      set :user, "root"
        parallel do |session|
          session.when "in?(:bootstrap)", "/etc/init.d/snoozenode stop ; /etc/init.d/snoozeimages stop; /etc/init.d/snoozeec2 stop; rm /tmp/snooze_*"
          session.when "in?(:groupmanager)", "cd #{snooze_deploy_localcluster_local_path}; ./start_local_cluster.sh -k ; killall java; rm /tmp/snooze_* "
          session.when "in?(:localcontroller)", "cd #{snooze_deploy_localcluster_local_path}; ./start_local_cluster.sh -k ; ./start_local_cluster.sh -d; killall java; rm /tmp/snooze_* "
        end

    end
  end # namespace custom

  desc 'Install Snooze on nodes'
  task :default do
    prepare::default
    provision::default
    plugins::default
    cluster::default
  end

  namespace :plugins do
    
    desc 'install plugins'
    task :default do
      install
    end

    task :install, :roles=> [:all] do
      set :user, "root"
      # todo (remove it ? )
      run "mkdir -p /usr/share/snoozenode/plugins"
      if defined?($plugins)
        $plugins.each do |plugin|
          run "#{wget} #{plugin[:url]} -O #{plugin[:destination]}"
         end
      end 
    end

  end


  namespace :prepare do  
    desc 'prepare the nodes'
    task :default do
      update
      modules
    end

    task :update, :roles => [:all] do
      run "#{proxy} apt-get update"
    end


    task :modules, :roles => [:frontend] do
      set :user, "#{g5k_user}"
      ls = capture("ls #{snooze_puppet_path} &2>&1")
      if ls!=""
        run "mv #{snooze_puppet_path} #{snooze_puppet_path}"+Time.now.to_i.to_s 
      end
      run "https_proxy='http://proxy:3128' git clone #{snooze_puppet_repo_url} #{snooze_puppet_path}" 
#      upload "/home/msimonin/github/snooze-puppet/", "#{snooze_puppet_path}", :via => :scp, :recursive => true
      run "#{wget} #{snoozenode_deb_url} -O #{snooze_puppet_path}/modules/snoozenode/files/snoozenode.deb 2>1"
      run "#{wget} #{snoozeclient_deb_url} -O #{snooze_puppet_path}/modules/snoozeclient/files/snoozeclient.deb 2>1"
      run "#{wget} #{snoozeimages_deb_url} -O #{snooze_puppet_path}/modules/snoozeimages/files/snoozeimages.deb 2>1"
      run "#{wget} #{snoozeec2_deb_url} -O #{snooze_puppet_path}/modules/snoozeec2/files/snoozeec2.deb 2>1"
      run "#{wget} #{kadeploy3_common_deb_url} -O #{snooze_puppet_path}/modules/kadeploy3/files/kadeploy-common.deb 2>1"
      run "#{wget} #{kadeploy3_client_deb_url} -O #{snooze_puppet_path}/modules/kadeploy3/files/kadeploy-client.deb 2>1"
    end

    task :reprepare, :roles => [:frontend] do
      set :user, "#{g5k_user}"
      run "#{wget} #{snoozenode_deb_url} -O #{snooze_puppet_path}/modules/snoozenode/files/snoozenode.deb 2>1"
      run "#{wget} #{snoozeclient_deb_url} -O #{snooze_puppet_path}/modules/snoozeclient/files/snoozeclient.deb 2>1"
    end

    task :purge, :roles => [:all] do
      set :user, "root"
      run "dpkg --purge snoozenode 2>1"
      run "rm -rf /opt/snoozenode"
      run "dpkg --purge snoozeimages 2>1"
      run "dpkg --purge snoozeclient 2>1"
    end
  end

 

  namespace :provision do
    
    desc 'Provision all the nodes'
    task :default do
      template
      transfer
      apply
    end

    task :template, :roles => [:subnet] do
      set :user, "#{g5k_user}"
      if "#{vlan}"=="-1"
        @virtualMachineSubnets = capture("g5k-subnets -p -j " + $myxp.job_with_name('subnet')['uid'].to_s).split
      else
        # generate subnets according to the kavlan id
        kavlan = capture("kavlan -V -j " + $myxp.job_with_name('kavlan')['uid'].to_s)
        b=(kavlan.to_i-10)*4+3
        @virtualMachineSubnets = (216..255).step(2).to_a.map{|x| "10."+b.to_s+"."+x.to_s+".1/23"} 
      end
      @version = "#{version}"

      bootstrap
      groupmanager
      localcontroller
    end

    task :transfer, :roles => [:frontend] do
      set :user, "#{g5k_user}"
      upload("#{snooze_path}/tmp/bootstrap.pp","#{snooze_puppet_path}/manifests/bootstrap.pp")
      upload("#{snooze_path}/tmp/groupmanager.pp","#{snooze_puppet_path}/manifests/groupmanager.pp")
      upload("#{snooze_path}/tmp/localcontroller.pp","#{snooze_puppet_path}/manifests/localcontroller.pp")
      upload("#{snooze_path}/templates/snooze_node.cfg.erb.#{version}", "#{snooze_puppet_path}/modules/snoozenode/templates/snooze_node.cfg.erb.#{version}")
    end


    task :bootstrap do
      template = File.read("#{snooze_path}/templates/snoozenode.erb")
      renderer = ERB.new(template)
      @nodeType             = "bootstrap"
      @zookeeperHosts       = "#{zookeeperHosts}"
      @zookeeperdHosts      = "#{zookeeperdHosts}"
      @externalNotificationHost = "#{rabbitmqServer}"
      @databaseCassandraHosts = cassandraHosts ? "#{cassandraHosts}" : "localhost"
      generate = renderer.result(binding)
      myFile = File.open("#{snooze_path}/tmp/bootstrap.pp", "w")
      myFile.write(generate)
      myFile.close
    end

    task :groupmanager do
      template = File.read("#{snooze_path}/templates/snoozenode.erb")
      renderer = ERB.new(template)
      @nodeType             = "groupmanager"
      @zookeeperHosts       = $myxp.get_deployed_nodes("bootstrap").first
      @zookeeperdHosts      = $myxp.get_deployed_nodes("bootstrap").first
      @externalNotificationHost = $myxp.get_deployed_nodes("bootstrap").first 
      generate = renderer.result(binding)
      myFile = File.open("#{snooze_path}/tmp/groupmanager.pp", "w")
      myFile.write(generate)
      myFile.close
    end


    task :localcontroller do
      template = File.read("#{snooze_path}/templates/snoozenode.erb")
      renderer = ERB.new(template)
      @nodeType             = "localcontroller"
      @zookeeperHosts       = $myxp.get_deployed_nodes("bootstrap").first
      @zookeeperdHosts      = $myxp.get_deployed_nodes("bootstrap").first
      @externalNotificationHost = $myxp.get_deployed_nodes("bootstrap").first 
      generate = renderer.result(binding)
      myFile = File.open("#{snooze_path}/tmp/localcontroller.pp", "w")
      myFile.write(generate)
      myFile.close
    end

    task :apply, :roles => [:bootstrap, :groupmanager, :localcontroller] do
      set :user, 'root'
      parallel do |session|
        session.when "in?(:bootstrap)", "puppet apply #{snooze_puppet_path}/manifests/bootstrap.pp --modulepath=#{snooze_puppet_path}/modules/"
        session.when "in?(:groupmanager)", "puppet apply #{snooze_puppet_path}/manifests/groupmanager.pp --modulepath=#{snooze_puppet_path}/modules/"
        session.when "in?(:localcontroller)", "puppet apply #{snooze_puppet_path}/manifests/localcontroller.pp --modulepath=#{snooze_puppet_path}/modules/"
      end
    end
  end
  
# Cluster configuration
namespace :cluster do

  desc 'Configure the cluster'
  task :default do
    bridge_network
    prepare
    copy
    interfaces
    context
    transfer
    fix_permissions
    
#    default_pool
#    local_pool

  end


  task :bridge_network, :roles => [:localcontroller] do
    set :user, 'root'
    upload "#{snooze_path}/network/interfaces", "/etc/network/interfaces"
    upload "#{snooze_path}/network/configure_network.sh", "/tmp/configure_network.sh"
    run "sh /tmp/configure_network.sh 2>/dev/null"
   end

  task :prepare, :roles=>[:first_bootstrap] do
    set :user, "root"
      ls = capture("ls /tmp/snooze/experiments &2>&1")
      if ls!=""
        run "mv /tmp/snooze/experiments /tmp/snooze/experiments"+Time.now.to_i.to_s 
      end
    run "#{proxy} apt-get -y install git" 
    run "https_proxy='http://proxy:3128' git clone  #{snooze_experiments_repo_url} /tmp/snooze/experiments" 
  end

  task :copy, :roles=>[:first_bootstrap] do
    set :user, "root"
    run "mkdir -p /tmp/snooze/images"

      ls = capture("ls #{snooze_imagesrepository_local_path}/debian-hadoop-context-big.qcow2 &2>&1")
      if ls==""
        run "#{wget} -O \
        #{snooze_imagesrepository_local_path}/debian-hadoop-context-big.qcow2 \
        http://public.rennes.grid5000.fr/~msimonin/debian-hadoop-context-big.qcow2 2>1"
      end

      ls = capture("ls #{snooze_imagesrepository_local_path}/resilin-base.raw &2>&1")
      if ls==""
        run "#{wget} -O \
        #{snooze_imagesrepository_local_path}/resilin-base.raw \
        http://public.rennes.grid5000.fr/~msimonin/resilin-base.raw 2>1"
      end

  end
  
  task :interfaces, :roles=>[:subnet] do
    set :user, "#{g5k_user}"
    if "#{vlan}"=="-1" 
      subnet_id = $myxp.job_with_name('subnet')['uid'].to_s
      @gateway=capture("g5k-subnets -j "+subnet_id+" -a | head -n 1 | awk '{print $4}'")
      @network=capture("g5k-subnets -j "+subnet_id+" -a | head -n 1 | awk '{print $5}'")
      @broadcast=capture("g5k-subnets -j "+subnet_id+" -a | head -n 1 | awk '{print $2}'")
      @netmask=capture("g5k-subnets -j "+subnet_id+" -a | head -n 1 | awk '{print $3}'")
      @nameserver="131.254.203.235"
    else
      kavlan = capture("kavlan -V -j " + $myxp.job_with_name('kavlan')['uid'].to_s)
      b=(kavlan.to_i-10)*4+3
      @gateway="10."+b.to_s+".255.254"
      @network="10."+b.to_s+".192.0"
      @broadcast="10."+b.to_s+".255.255"
      @netmask="255.255.192.0"
      @nameserver="131.254.203.235"
    end
    template = File.read("#{snooze_path}/templates/network.erb")
    renderer = ERB.new(template)
    generate = renderer.result(binding)
    myFile = File.open("#{snooze_path}/network/context/common/network", "w")
    myFile.write(generate)
    myFile.close
  end

  task :context  do
    system "#{mkisotool} #{snooze_path}/tmp/context.iso #{snooze_path}/network/context 2>/dev/null"
  end

  task :transfer, :roles =>[:first_bootstrap] do
     set :user, "root"
     run "mkdir -p /tmp/snooze/images"
     upload "#{snooze_path}/tmp/context.iso", "#{snooze_imagesrepository_local_path}/.", :via => :scp
  end
  
  task 'fix_permissions', :roles => [:first_bootstrap] do
    set :user, "root"
    run "chown -R snoozeadmin:snooze /tmp/snooze"
    run "chmod -R 755 #{snooze_imagesrepository_local_path}"
  end

=begin
  task 'default_pool', :roles => [:first_bootstrap] do
    set :user, "root"
    run "virsh  pool-define-as --name default --type dir --target /tmp/snooze/images"
    run "virsh  pool-start default"
    run "virsh  pool-refresh default"
    run "virsh  pool-autostart default"
  end
=end

=begin
  task 'local_pool', :roles => [:localcontroller] do
    set :user, "root"
    run "chown root:snooze /var/lib/libvirt/images"
    run "chmod 775 /var/lib/libvirt/images"
  end
=end

  desc 'Start cluster'
  task :start, :roles => [:bootstrap, :groupmanager, :localcontroller] do
    set :user, "root"
      parallel do |session|
        session.when "in?(:bootstrap)", "/etc/init.d/snoozenode start ; /etc/init.d/snoozeimages start; /etc/init.d/snoozeec2 start"
        session.when "in?(:localcontroller)", " service libvirt-bin restart ; /etc/init.d/snoozenode start"
        session.when "in?(:groupmanager)", "/etc/init.d/snoozenode start"
      end
  end

  desc 'Stop cluster'
  task :stop, :roles => [:bootstrap, :groupmanager, :localcontroller] do
    set :user, "root"
      parallel do |session|
        session.when "in?(:bootstrap)", "/etc/init.d/snoozenode stop ; /etc/init.d/snoozeimages stop; /etc/init.d/snoozeec2 stop; rm /tmp/snooze_*"
        session.when "in?(:groupmanager)", "/etc/init.d/snoozenode stop ; rm /tmp/snooze_* "
        session.when "in?(:localcontroller)", "/etc/init.d/snoozenode stop ; killall kvm 2>1 ; rm /tmp/snooze_*"
      end
  end

  desc 'Wake Up localcontrollers'
  task :wakeup, :roles => [:frontend] do
    set :user, "#{g5k_user}"
    localcontrollers = find_servers :roles => :localcontroller
    localcontrollers.each do |localcontroller|
      run "kapower3 -m #{localcontroller} --on"
    end
  end

  desc 'Power down localcontrollers'
  task :shutdown, :roles => [:frontend] do
    set :user, "#{g5k_user}"
    localcontrollers = find_servers :roles => :localcontroller
    localcontrollers.each do |localcontroller|
      run "kapower3 -m #{localcontroller} --off"
    end
  end

  # Dummy vm management ...
  namespace :vms do
    task :start, :roles=>[:first_bootstrap] do
      set :user, "root"
      run "cd /tmp/snooze/experiments ; ./experiments.sh -c "+ ENV['vcn']+ " "+ENV['vms']
      run "snoozeclient start -vcn " + ENV['vcn']
    end

    task :destroy, :roles=>[:first_bootstrap] do
      set :user, "root"
      run "snoozeclient destroy -vcn " + ENV['vcn']
    end
  end

 end # cluster

  namespace :webinterface do

    desc 'Deploy snooze web interface'
    task :default do
      install::default  
      launch
      summary
    end

    namespace :install do
      desc 'Install the needed stuffs'
      task :default do
        packages
        files
        bundle
        gems
      end
      
      task :packages   , :roles => [:webinterface] do
        set :user, "root"
        run "apt-get update"
        run "apt-get -y install git"
      end

      task :files, :roles => [:webinterface] do
        set :user, "#{g5k_user}"
        run "http_proxy='http://proxy:3128' https_proxy='http://proxy:3128' git clone #{webinterface_url} #{webinterface_directory}"
        #upload "#{webinterface_url}", "#{webinterface_directory}", :via => :scp, :recursive => true
      end

      task :bundle, :roles => [:webinterface] do
        set :user, "root"
        run "http_proxy='http://proxy:3128' https_proxy='http://proxy:3128' gem install bundler"
      end

      task :gems, :roles => [:webinterface] do
        set :user, "#{g5k_user}"
        run "cd #{webinterface_directory} ; http_proxy='http://proxy:3128' https_proxy='http://proxy:3128' bundle install"
      end
    end

    task :launch, :roles => [:webinterface] do
      set :user, "#{g5k_user}"
      run "cd #{webinterface_directory} ; nohup rackup -p 80 > /tmp/webinterface 2>&1 & "
    end

    task :summary do
      webui = find_servers :roles => [:webinterface]
      host = webui.first.host.split('.').insert(2,'proxy-http').join('.')
      puts <<-EOF
        +------------------ Snooze Web Interface -------------+
                                                            
         Connect to :                                      
                                                             
         https://#{host}
        +-----------------------------------------------------+
      EOF

    end


  end

end

