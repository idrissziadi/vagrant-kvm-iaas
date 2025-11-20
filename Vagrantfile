Vagrant.configure("2") do |config|
  # VM kvm1 – Serveur KVM
  config.vm.define "kvm1" do |kvm1|

    kvm1.vm.box = "generic/centos9s"
    kvm1.vm.hostname = "kvm1.esi.dz"
    # eth0 par defaut en NAT
    # eth1
    kvm1.vm.network "private_network", ip: "10.10.0.1"
   
    kvm1.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "kvm1"
      v.memory = 2048
      v.cpus = 2
    end

 
    kvm1.vm.provision "shell", path: "./installServerKVM.sh"
  end





  # VM client1 – Client KVM
  config.vm.define "client1" do |client1|
    client1.vm.box = "generic/centos9s"
    client1.vm.hostname = "client1.esi.dz"

    client1.vm.network "private_network", ip: "10.10.0.10"

    client1.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "client1"
      v.memory = 1024
      v.cpus = 1
    end

    client1.vm.provision "shell", path: "./installClientKVM.sh"
  end
end
