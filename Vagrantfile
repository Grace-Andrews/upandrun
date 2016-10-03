# -*- mode: ruby -*-
# vi: set ft=ruby :

case Vagrant::VERSION
when /^1\.[1-4]/
  Vagrant.require_plugin('oscar')
else
  # The require_plugin call is deprecated in 1.5.x. Replacement? Dunno.
end

if defined? Oscar
  
  class ReloadPluginSupport < ::ConfigBuilder::Model::Base
    def to_proc
      Proc.new do |vm_config|
        vm_config.provision :reload
      end
    end
 
    ::ConfigBuilder::Model::Provisioner.register('reload', self)
  end

  vagrantdir = File.dirname(__FILE__)
  configdir  = File.expand_path('config', vagrantdir)
  Vagrant.configure('2', &Oscar.run(configdir))

  # Ensure directory exists for local content repo
  stackdir = '/Users/Shared/seteam-vagrant-stack'
  link     = File.expand_path('.files', vagrantdir)

  # Right now this only works for *nix like operatingsystems, but presumably we
  # could support Windows Junctions as well.
  Dir.mkdir(stackdir, 0755) unless File.exists?(stackdir)
  File.symlink(stackdir, link) unless File.symlink?(link)
end
