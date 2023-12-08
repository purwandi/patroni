Vagrant.configure(2) do |config|
  
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/me.pub"
  config.vm.provision "file", source: "src/consul", destination: "~/.local/bin/consul"

  config.vm.provision "shell", path: "helper/bootstrap.sh"

  config.vm.define "bastion" do |node|
    node.vm.box               = "almalinux/9"
    node.vm.box_check_update  = false
    node.vm.hostname          = "bastion"
    node.vm.network "private_network", ip: "10.0.0.2"
    node.vm.provider :virtualbox do |v|
      v.memory  = 512
      v.cpus    = 1
    end
  end

  (1..3).each do |i|
    config.vm.define "consul-0#{i}" do |node|

      node.vm.box               = "almalinux/9"
      node.vm.box_check_update  = false
      node.vm.hostname          = "consul-0#{i}"
      node.vm.network "private_network", ip: "10.0.0.1#{i}"

      node.vm.provider :virtualbox do |v|
        v.memory  = 512
        v.cpus    = 1
      end

      node.vm.provision "shell", path: "helper/bootstrap-consul.sh"
      
    end
  end

  (1..2).each do |i|
    config.vm.define "database-0#{i}" do |node|
      node.vm.box               = "almalinux/9"
      node.vm.box_check_update  = false
      node.vm.hostname          = "database-0#{i}"
      node.vm.network "private_network", ip: "10.0.0.2#{i}"

      node.vm.provider :virtualbox do |v|
        v.memory  = 1024
        v.cpus    = 1
      end

      node.vm.provision "shell", path: "helper/bootstrap-patroni.sh"

    end
  end
end