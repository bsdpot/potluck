---
author: "Bretton Vine"
title: Grafana 
summary: Grafana is a visualisation front-end for data, specifically system metrics.
tags: ["metrics", "charts", "grafana"]
---

# Overview

This is a flavour containing the ```grafana``` visualisation interface used to view ```prometheus``` or ```loki``` data sources among others.

It also contains ```node_exporter``` and a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/grafanadata zroot/grafanadata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/grafanadata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 3000:3000```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
  -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
  -E PROMSOURCE="10.0.0.1" -E LOKISOURCE="10.0.0.2" -E INFLUXDBSOURCE="10.0.0.3" -E INFLUXDATABASE=<database name> \
  [-E GRAFANAUSER=<username> -E GRAFANAPASSWORD=<password> \ 
  [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>] [-E REMOTELOG=<remote syslog IP>]
  ```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The PROMSOURCE parameter is the IP address of the ```prometheus``` data source.

The LOKISOURCE parameter is the IP address of the ```loki``` data source.

The INFLUXDBSOURCE parameter is the IP address of the ```influxdb``` data source. The INFLUXDATABASE parameter must also be set with the name of the database to query.

The default ```grafana``` user and password is ```admin```, however you can set your own credentials with the parameters GRAFANAUSER and GRAFANAPASSWORD.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

# Usage

To access ```grafana``` open the following in a browser:
* https://<grafana-host>:3000

# Persistent Storage
Persistent storage will be in the ZFS data set zroot/grafanadata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because ```grafana``` is configured to use this directory for data.

# Problems to pay attention to
The default installation of ```grafana``` on FreeBSD has a known bug where ```grafana``` crashes, or crashes on a restart:
```
grafana[96320]: panic: error getting work directory: stat .: permission denied
grafana[96320]: 
grafana[96320]: goroutine 1 [running]:
grafana[96320]: gopkg.in/macaron%2ev1.init.1()
grafana[96320]:         gopkg.in/macaron.v1/macaron.go:317 +0x110
```

Workable solutions are presented at https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676

This image has implemented both options:
* remove ```/usr/bin/env ${grafana_env}``` from command args
* add ```chmod 755 /root``` to pot flavour script

Important: These are non-standard permissions for /root and allow any user on the system to read files in /root.
