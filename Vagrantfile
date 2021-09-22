
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.define "debian-10" do |box|
        box.vm.box = "debian/stretch64"
        box.vm.box_version = "10.4.0"
        box.vm.hostname = "debian-10.local"
        box.vm.network "private_network", ip: "192.168.48.102"
        box.vm.synced_folder ".", "/vagrant", type: "virtualbox"
        box.vm.provision "shell", path: "debian-10.sh"
        box.vm.provider "VirtualBox" do |vb|
          vb.gui = false
          vb.memory = 2000
        end

    end

end
    