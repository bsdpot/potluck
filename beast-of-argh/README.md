---
author: "Bretton Vine"
title: Beast of Argh 
summary: Beast of Argh is a single pot image with Prometheus, Alertmanager, Loki, Promtail, Grafana and dashboards, plus syslog server, for monitoring and alerting of small environments.
tags: ["monitoring", "alerting", "logs", "syslog", "prometheus", "alertmanager", "loki", "promtail", "grafana"]
---

# Overview

![Beast of Argh](beast-of-argh.jpg)

This is a mega-flavour containing the ```prometheus``` time series database, ```alertmanager``` alert notification queue, ```loki``` log monitoring, ```promtail``` log ingestor,  and ```grafana``` viewer with custom dashboards.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/beastdata zroot/beastdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/beastdata```
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
    -E GRAFANAUSER=<grafana username> \
    -E GRAFANAPASSWORD=<grafana password> \
    -E SCRAPECONSUL='<correctly formatted list of quoted IP addresses>' \
    -E SCRAPENOMAD='<correctly formatted list of quoted IP addresses>' \
    -E TRAEFIKSERVER='<ip:port of traefik-consul instance>' \
    -E SMTPHOSTPORT="10.0.0.2:25" \
    -E SMTPFROM=<from email address> \
    -E ALERTADDRESS=<to email address> \
    [ -E SMTPUSER=<smtp auth username> -E SMTPPASS=<smtp auth password> ]
  ```

## Required Paramaters
The DATACENTER parameter defines a common datacenter. 

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The GRAFANAUSER and GRAFANAPASSWORD parameters are to set a custom user/pass for Grafana.

The SCRAPECONSUL parameter is a list of consul servers to scrape data from. Metrics must be configured in consul.

The SCRAPENOMAD parameter is a list of nomad servers to scrape data from. Metrics must be configured in nomad.

The TRAEFIKSERVER parameter is the IP address and port of a `traefik-consul` instance to scrape metrics from. It must be setup with metrics endpoint.

The SMTPHOSTPORT parameter is the IP address and port of the mail server to use when sending alerts.

The SMTPFROM parameter is the from address of the account sending alerts via mail.

The ALERTADDRESS parameter is the destination address for alerts.

## Optional Parameters

The SMTPUSER and SMTPPASS parameters are credentials for smtp auth. 

# Loki Explanation

There are several components to having a searchable log-ingestor:

## 1. Remote syslog server accepting incoming logs

```syslogd``` is configured to accept syslog on UDP port 514 from hosts in the specified subnet, and save all to ```/mnt/logs/central.log```.

Remote hosts have their syslog.conf configured to send logs to this host.

This is a very broad and blunt approach, where ```syslog-ng``` may be a preferred approach with wildcard capabilities and multiple files.

## 2. Promtail log parsing and labelling

```promtail``` is configured as a service and monitors ```/mnt/logs/central.log``` for data to ingest and label, before submitting to ```loki```.

## 3. Loki data source

```loki``` is configured as a service and ingests data-with-labels, and makes available for query purposes.

## 4. Grafana with "search logs" dashboard

```grafana``` is a viewer for the data in the ```loki``` data source. A separate ```grafana``` flavour must be configured with ```loki``` as a data source to view captured logs. 

# Usage

Access grafana dashboards at ```http://yourhost:3000``` and choose from various dashboards, or access ```loki``` logs via the ```search logs``` dashboard.

Access ```prometheus``` at ```http://yourhost:9090```.

Access ```alertmanager``` at ```http://yourhost:9093```.

# Dynamic inventory for scrape targets

File-based scrape targets are configured for the following files, which you can copy in replacements to, or update on the system.

(assumes persistent storage mounted in)

* /mnt/prometheus/targets.d/mytargets.yml
* /mnt/prometheus/targets.d/postgres.yml

These files need to in the format:
```
- targets:
  - <fqdn or ip>:<optional port>
  labels:
    job: jobtype1
```

# Persistent Storage
Persistent storage will be in the ZFS dataset zroot/beastdata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS dataset, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because the included applications are configured to use this directory for data.

# Client-side syslog-ng configuration
Please see the included file `client-syslog-ng.conf.sample` and configure:

`%%config_version%%` is the syslog-ng config version in X.YY (not X.YY.Z). You can extract a suitable value to update in scripts using:

```
/usr/local/sbin/syslog-ng --version | grep '^Config version:' | awk -F: '{ print \$2 }' | xargs
```

`%%remotelogip%%` is the IP address of the Beast of Argh pot jail.

Update manually or via `sed` in scripts.