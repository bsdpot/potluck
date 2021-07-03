---
author: "Bretton Vine"
title: Prometheus 
summary: Prometheus is a tool for capturing time series data, specifically system metrics.
tags: ["metrics", "time-series", "prometheus", "grafana"]
---

# Overview

This is a flavour containing the ```prometheus``` time series database.

It also contains ```node_exporter``` and ```grafana```.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create a ZFS dataset on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/prometheusdata zroot/prometheusdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS dataset you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/prometheusdata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 9090:9090 -e 9100:9100 -e 3000:3000```
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
      -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
      -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
      [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.


# Usage

To access prometheus open the following in a browser:
* http(s)://<prometheus-host>:9090
* http(s)://<prometheus-host>:9090/targets/

To access this node's own metrics, visit:
* http(s)://<prometheus-host>:9100/metrics

or run ```fetch -o - 'https://127.0.0.1:9100/metrics'```

To see the targets being captured via consul, visit
* http://<prometheus-host>:9090/targets

To access Grafana open the following in a browser:
* http(s)://<prometheus-host>:3000

Note: Grafana should start automatically, and starts up with ```service grafana start``` instead of ```/usr/local/etc/rc.d/grafana start``` which wasn't working.

# Persistent Storage
Persistent storage will be in the ZFS dataset zroot/prometheusdata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS dataset, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because Prometheus & Grafana are configured to use this directory for data.
