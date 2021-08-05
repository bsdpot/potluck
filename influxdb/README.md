---
author: "Bretton Vine"
title: InfluxDB 
summary: InfluxDB is a time-series database
tags: ["time series", "influxdb", "grafana"]
---

# Overview

This is a flavour containing the ```inflexdb``` datasource.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create a ZFS dataset on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/influxdbdata zroot/influxdbdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS dataset you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/influxdbdata```
* Copy in the SSH private key for the user on the Vault leader:    
  ```pot copy-in -p <jailname> -s /root/sshkey -d /root/sshkey```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e XX:XX```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
  -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
  -E SFTPUSER=<user> -E SFTPPASS=<password>
  -E REMOTELOG=<IP> [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>]
  ```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The SFTPUSER and SFTPPASS parameters are for the user on the ```vault``` leader in the VAULTSERVER parameter. You need to copy in the id_rsa from there to the host of this image.

# Usage

To access ```influxdb``` make sure your ```grafana``` flavour has a datasource with this host's IP:
* https://<influxdb-host>:8086

# Persistent Storage
Persistent storage will be in the ZFS dataset zroot/influxdbdata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS dataset, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because Loki is configured to use this directory for data.
