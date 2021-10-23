---
author: "Bretton Vine"
title: Prometheus 
summary: Prometheus is a tool for capturing time series data, specifically system metrics.
tags: ["metrics", "time-series", "prometheus", "grafana"]
---

# Overview

This is a flavour containing the ```prometheus``` time series database along with the ```alertmanager``` notification tool configured for email alerts.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/prometheusdata zroot/prometheusdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/prometheusdata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 9090:9090 -e 9100:9100 -e 3000:3000```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
  -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
  -E SFTPUSER=<user> -E SFTPPASS=<password> \
  -E SCRAPECONSUL="'10.0.0.1:8501', '10.0.0.2:8501', '10.0.0.3:8501', '10.0.0.4:8501', '10.0.0.5:8501'" \
  -E SCRAPENOMAD="'10.0.0.6:4646', '10.0.0.7:4646', '10.0.0.8:4646', '10.0.0.9:4646', '10.0.0.10:4646'" \
  -E SCRAPEDATABASE="'10.0.0.11:9187', '10.0.0.12:9187'" \
  -E SMTPHOSTPORT="smtp.host.com:25" -E SMTPFROM="alertmanager@example.com" \
  -E ALERTADDRESS="<email address to notify>" \
  [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>] [-E REMOTELOG=<remote syslog IP>]
  ```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The SCRAPECONSUL parameter is a list of ```consul``` servers with port 8501 for TLS, to pass into prometheus.yml.

The SCRAPENOMAD parameter is a list of ```nomad``` servers with port 4646 for TLS, to pass into prometheus.yml.

The SCRAPEDATABASE parameter is a list of ```postgres_exporter``` instances on ```postgresql-patroni``` images, with port 9187 to pass into prometheus.yml.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

The SMTPHOSTPORT parameter is for ```alertmanager``` and must be entered in as ```smtphostname:port```.

The SMTPFROM parameter is the ```alertmanager``` FROM email address.

The SMTPUSER and SMTPPASS parameters are for SMTP authentication.

The ALERTADDRESS parameter is the email address to send notifications to.

# Usage

To access prometheus open the following in a browser:
* http://<prometheus-host>:9090
* http://<prometheus-host>:9090/targets/

To access this node's own metrics, visit:
* http://<prometheus-host>:9100/metrics

or run ```fetch -o - 'https://127.0.0.1:9100/metrics'```

To see the targets being captured via consul, visit
* http://<prometheus-host>:9090/targets

To access Grafana open the following in a browser and accept the self-signed certificate:
* https://<prometheus-host>:3000

# Persistent Storage
Persistent storage will be in the ZFS data set zroot/prometheusdata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because Prometheus is configured to use this directory for data.
