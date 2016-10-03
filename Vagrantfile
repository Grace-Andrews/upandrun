Vagrant.configure("2") do |config|

  config.vm.define "master.vm" do |master|
    master.vm.box = "centos/7"
    master.vm.hostname = "master.vm"
    master.vm.provision "shell", path: "scripts/masterbootstrap.sh"
    master.vm.network :private_network, ip: "192.168.50.4"
    master.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
    end
  end 

  config.vm.define "windows.vm" do |windows|
    windows.vm.box = "ferventcoder/win2012r2-x64-nocm"
    windows.vm.communicator = "winrm"
    windows.vm.hostname = "windows"
    windows.vm.provision "shell", path: "scripts/windows_agent.ps1"
    windows.vm.network "private_network", ip: "192.168.50.5"
    windows.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end
  end

  config.vm.define "linux.vm" do |linux|
    linux.vm.box = "centos/7"
    linux.vm.hostname = "linux.vm"
    linux.vm.network "private_network", ip: "192.168.50.6"
    linux.vm.provision "shell", path: "scripts/linux_agent.sh"
    linux.vm.network :private_network, ip: "192.168.50.6"
    linux.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end
  end
end
