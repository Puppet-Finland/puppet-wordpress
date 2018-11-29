# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "wordpress" do |box|
    box.vm.box = "centos/7"
    box.vm.box_version = "1804.02"
    box.vm.hostname = "wordpress.local"
    box.vm.network "private_network", ip: "192.168.71.100"
    box.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    box.vm.provision "shell" do |s|
      s.path = "vagrant/prepare.sh"
      s.args = ["-n", "wordpress", "-f", "redhat", "-o", "el-7", "-b", "/home/vagrant"]
    end
    box.vm.provision "shell", inline: "puppet apply --modulepath /home/vagrant/modules /vagrant/vagrant/wordpress.pp"
    box.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = 1024
    end
  end
end
