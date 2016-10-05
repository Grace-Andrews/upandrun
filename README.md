# upandrun #

A very simple vagrant environment for getting up and running with Puppet Enterprise. 

This repo provides you with a complete, yet simple environment that consists of a master (CentOS7), as well as a Linux (CentOS7) and Windows VM. 

## Pre-Steps ##

Before cloning this repo, you'll have to install both [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads). 

Once both are installed, you'll be able to do the following steps from your CLI:

```
'git clone https://github.com/Grace-Andrews/upandrun'

'cd upandrun'

'vagrant up'

'vagrant hosts list'

'vagrant ssh <IPaddress for Master>'
```

In order to get into your boxes, you can either ssh in from your command line, or you can use the VirtualBox interface.
