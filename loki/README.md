---
author: "Bretton Vine"
title: Loki 
summary: Loki is a tool for viewing centralised log data, and extracting alerts and metrics for export to Prometheus
tags: ["logs", "syslog", "loki", "grafana"]
---

# Overview

This is a flavour containing the ```loki``` datasource, ```promtail``` log ingestor,  and ```grafana``` viewer.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create a ZFS dataset on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/lokidata zroot/lokidata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS dataset you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/lokidata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 3100:3100 -e 3000:3000```
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
      -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
      -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
      -E LOGCLIENTS="10.0.0.0/24" [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The LOGCLIENTS parameter is a network subnet to accept remote syslog entries from. Any host in this range configured to send logs to this server will be accepted.

# Explanation

There are several components to having a searchable log-ingestor:

## 1. Remote syslog server accepting incoming logs

```syslogd``` is configured to accept syslog on UDP port 514 from hosts in the specified subnet, and save all to ```/mnt/logs/central.log```.

Remote hosts have their syslog.conf configured to send logs to this host.

This is a very broad and blunt approach, where ```syslog-ng``` may be a preferred approach with wildcard capabilities and multiple files.

## 2. Promtail log parsing and labelling

```promtail``` is configured as a service and monitors ```/mnt/logs/central.log``` for data to ingest and label, before submitting to ```loki```.

## 3. Loki datasource

```loki``` is configured as a service and ingests data-with-labels, and makes available for query purposes.

## 4. Grafana with "search logs" dashboard

```grafana``` is a viewer for the data in the ```loki``` datasource. A separate ```grafana``` flavour must be configured with ```loki``` as a datasource to view captured logs. 

# Usage

To access ```loki``` make sure your ```grafana``` flavour has a datasource with this host's IP:
* https://<loki-host>:3000
and open the ```search logs``` dashboard.

# Persistent Storage
Persistent storage will be in the ZFS dataset zroot/lokidata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS dataset, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because Loki is configured to use this directory for data.
