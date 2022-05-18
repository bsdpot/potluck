---
author: "Bretton Vine"
title: Traumadrill 
summary: Traumadrill is a single pot image with multiple benchmarking tools and stress generators for generating artificial system load.
tags: ["monitoring", "alerting", "benchmarking", "stress", "alertmanager", "testing"]
---

# Overview

This flavour currently contains the tools ```stress-ng``` and ```sysbench``` for generating artificial load and testing alert rules.

It is a continual work-in-progress for testing ```prometheus``` alert rules for system load within a pot environment.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Optionally create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/stressdata zroot/stressdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Optionally mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/stressdata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 3100:3100 -e 3000:3000```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
    [ -E REMOTELOG=<IP address> ]
  ```

## Required Paramaters
The DATACENTER parameter defines a common datacenter. 

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

## Optional Parameters

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

TODO update usage portion of docs

