---
author: "Bretton Vine"
title: Jenkins
summary: Jenkins is a tool used for Continuous Integration (CI) and testing
tags: ["CI", "testing", "automated builds", "jenkins"]
---

# Overview

This is a flavour containing the ```jenkins``` Continuous Integration (CI) and testing tool.

It has been setup with a specific purpose of automating pot images builds, thus the requirement for a BUILDHOST IP address of a server or VM running FreeBSD and Pot, with SSH access enabled for the jenkins user.

You can adjust this flavour and rebuild your own pot image if you have other requirements.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/jenkins zroot/jenkinsdata```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created:
  ```pot mount-in -p <jailname> -d /mnt/jenkins -m /mnt/```
* Optionally copy in SSH private key:
  ```pot copy-in -p <jailname> -s /path/to/jenkins/id_rsa -d /root/jenkins.key```
* Optionally copy in SSH public key:
  ```pot copy-in -p <jailname> -s /path/to/jenkins/id_rsa.pub -d /root/jenkins.pub```
* Optionally export the ports after creating the jail:
  ```pot export-ports -p <jailname> -e 8080:8080```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS=<comma-deliminated list of consul servers> \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
    -E RUNTYPE=<nostore|setupstore|activestore> \
    -E BUILDHOST=<IP of potbuilder VM> \
    [ -E IMPORTKEYS=<1|0 default> ] \
    [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

RUNTYPE is one of:
* ```nostore```, no persistent storage. anything you setup will be lost on reboot
* ```setupstore```, setup persistent storage the first time by copying over the regular jenkins installation
* ```activestore```, run from persistent storage, without copying over jenkins installation first

BUILDHOST is the IP address of a VM or server running FreeBSD and pot, to build jail images.

IMPORTKEYS defaults to 0 and sets up new keys for jenkins user. Set to 1 to import existing SSH keys to use.
Copy in the files id_rsa & id_rsa.pub as part of the pot setup and start process.

The REMOTELOG parameter is the IP address of a syslog-ng server, such as with a `loki` or `beast-of-argh` pot image.

# Usage

## No persistent storage

To access ```jenkins```:
* http://jenkins-host:8080

Setup takes a little while the first time, and you will need console access to the ```jenkins``` pot image to run:

```
cat /usr/local/jenkins/secrets/initialAdminPassword
```

On first usage plugins will need to be setup and this takes a little time too, and requires internet access to download files.

## Persistent storage

To use persistent storage and launch repeatedly without setting up again, configure mount-in storage, and run once with RUNTYPE set to `setupstore`, shut down, then run thereafter with RUNTYPE
set to `activestore`.

Setup takes a little while the first time, and you will need console access to the ```jenkins``` pot image to run:

```
cat /mnt/jenkins/secrets/initialAdminPassword
```

On first usage plugins will need to be setup and this takes a little time too, and requires internet access to download files.

# Persistent Storage
Persistent storage will be in the ZFS data set zroot/jenkinsdata, available inside the image at /mnt/jenkins

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because ```jenkins``` is configured to use this directory for data.

# Consul DNS

Consul DNS works in the format `servicename.service.consul` or `nodename.node.consul`.

Consul DNS is integrated with local unbound in this image. You can query consul DNS like any normal DNS query directly to localhost.

To get a list of services listed in `consul` you can do the following:

```
curl -s "http://127.0.0.1:8500/v1/catalog/services" | jq
```

You can query the IP address of a service with

```
drill servicename.service.consul
```
