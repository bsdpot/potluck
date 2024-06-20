---
author: "Bretton Vine"
title: Beast of Argh
summary: Beast of Argh is a single pot image with Prometheus, Alertmanager, Loki, Promtail, Grafana and dashboards, plus syslog server, for monitoring and alerting of small environments.
tags: ["monitoring", "alerting", "logs", "syslog", "prometheus", "alertmanager", "loki", "promtail", "grafana"]
---

# Overview

![Beast of Argh](beast-of-argh.png)

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
    -E CONSULSERVERS=<consul IP address(es) in comma-deliminated format> \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
    -E GRAFANAUSER=<grafana username> \
    -E GRAFANAPASSWORD=<grafana password> \
    -E SCRAPECONSUL=<consul IP address(es) in comma-deliminated format> \
    -E SCRAPENOMAD=<nomad IP address(es) in comma-deliminated format> \
    -E TRAEFIKSERVER=<ip:port of traefik-consul instances in comma-deliminated format> \
    -E SMTPHOSTPORT="10.0.0.2:25" \
    -E SMTPFROM=<from email address> \
    -E ALERTADDRESS=<to email address> \
    [ -E SMTPUSER=<smtp auth username> -E SMTPPASS=<smtp auth password> ]
  ```

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter defines the consul server instances, from one to five IP addresses in comma-deliminated format and no spaces.

```-E CONSULSERVERS="10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The GRAFANAUSER and GRAFANAPASSWORD parameters are to set a custom user/pass for Grafana.

The SCRAPECONSUL parameter is a comma-deliminated list of consul servers to scrape data from. Metrics must be configured in consul.

```-E SCRAPECONSUL="10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5"```

The SCRAPENOMAD parameter is a comma-deliminated list of nomad servers to scrape data from. Metrics must be configured in nomad.

```-E SCRAPENOMAD="10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5"```

The TRAEFIKSERVER parameter is comma-deliminated list of IP:port of `traefik-consul` instances to scrape metrics from. They must be setup with a metrics endpoint.

```-E TRAEFIKSERVER="10.0.0.1:8082,10.0.0.2:8082"```

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

File-based scrape targets are configured for the following files, which you can copy in replacements for, or update on the system.

(assumes persistent storage mounted in)

* /mnt/prometheus/targets.d/blackboxhosts.yml
* /mnt/prometheus/targets.d/mytargets.yml
* /mnt/prometheus/targets.d/postgres.yml
* /mnt/prometheus/targets.d/minio.yml
* /mnt/prometheus/targets.d/redis.yml

These files need to in the format:
```
- targets:
  - <ip>:<port>
  labels:
    job: jobtype1
```

The targets file for blackbox hosts has a slightly different format
```
#########################################################################
# <BLACKBOX_EXPORTER_IP_PORT>:_:<<MODULE>:_:<LOCATION>:_:<TARGET_URL>   #
#########################################################################
- targets:
  - 1.2.3.4:9115:_:http_2xx:_:DC1:_:http://prometheus.io
  - 1.2.3.5:9115:_:http_2xx:_:CapeTown:_:https://prometheus.io
  - 1.2.3.6:9115:_:http_2xx:_:DC1:_:http://example.com:8080
  - 1.2.3.7:9115:_:icmp_ipv4:_:DC1:_:10.0.0.1
```

You do not need to restart prometheus when changing the files in /mnt/prometheus/targets.d/ to take effect.

## Scraping minio metrics

This image is setup with the assumption of a self-signed certificate for minio, and env ```MINIO_PROMETHEUS_AUTH_TYPE=public``` configured on minio start.

Test metrics scraping with ```curl -k https://your-minio-host:9000/minio/v2/metrics/cluster``` and if successful, add targets to the file ```/mnt/prometheus/targets.d/minio.yml``` in the format:

```
- targets:
  - your-minio-host:9000
  - your-other-minio:9000
  labels:
    job: minio
```

If you require authentication, you can adjust the ```minio``` scrape job in the file ```/usr/local/etc/prometheus.yml```, via external script, after image boot and with a reload of ```prometheus```, to include the relevant token option and optional SSL config.

# Persistent storage

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

# Alertmanager Silences

Some alerts will trigger automatically. 

For example, if there is no Mariadb Galera cluster, there will be an alert about the Galera cluster not being ready.

Add a silence to this alert with an expiry of 52 weeks, and leave a comment of 52 weeks. Then do it again in a year.

There is also a Dead Man's Switch alert, which needs to be silenced in a similar manner. 

The purpose of this alert is to verify processes are functioning correctly for alerting and response.

Out of memory alerts may also crop up and can be silenced for a few weeks. Pot jails can utilise most of the memory allocated to them, and this will trigger an alert. However everything will be functioning normally.

It's useful to leave a comment with the delay time set.