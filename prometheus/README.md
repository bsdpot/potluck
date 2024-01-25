---
author: "Stephan Lichtenauer, Bretton Vine, Michael Gmelin"
title: Prometheus
summary: Prometheus is a tool for capturing time series data, specifically system metrics.
tags: ["metrics", "time-series", "prometheus", "grafana"]
---

# Overview

This is a flavour containing the `prometheus` time series database along
with the `alertmanager` notification tool configured for email alerts.

The flavour includes a local `consul` agent instance to be available that it
can connect to (see configuration below). You can, e.g., use the
[consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour on this
site to run `consul`.

# Installation

* Create a ZFS data set on the parent system beforehand
  `zfs create -o mountpoint=/mnt/prometheusdata zroot/prometheusdata`
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  `pot mount-in -p <jailname> -m /mnt -d /mnt/prometheusdata`
* Optionally export the ports after creating the jail:
  `pot export-ports -p <jailname> -e 9090:9090 -e 9100:9100 -e 3000:3000`
* Adjust to your environment:

      sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> \
        -E NODENAME=<nodename> -E IP=<IP address of this system> \
        -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
        -E SCRAPECONSUL='<correctly formatted list of quoted IP addresses>' \
        -E SCRAPENOMAD='<correctly formatted list of quoted IP addresses>' \
        -E SMTPHOSTPORT="smtp.host.com:25" -E SMTPFROM="alertmanager@example.com" \
        -E ALERTADDRESS="<email address to notify>" \
        [-E SMTPUSER=<smtp auth user> -E SMTPPASS=<smtp auth password>] \
        [-E REMOTELOG=<remote syslog IP>] [-E DNSFORWARDERS=<none|list of IPs>]

The CONSULSERVERS parameter defines the consul server instances, and must be
set as
* `CONSULSERVERS='"10.0.0.2"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'`

The SCRAPECONSUL parameter is a list of `consul` servers with port for TLS
(usually 8501), to pass into prometheus.yml.

The SCRAPENOMAD parameter is a list of `nomad` servers with port for TLS
(usually 4646), to pass into prometheus.yml.

The REMOTELOG parameter is the IP address of a remote syslog server to send
logs to, such as for the `loki` flavour on this site.

The DNSFORWARDERS parameter is a space delimited list of IPs to forward DNS
requests to. If set to `none` or left out, no DNS forwarders are used.

The SMTPHOSTPORT parameter is for `alertmanager` and must be entered in as
`smtphostname:port`.

The SMTPFROM parameter is the `alertmanager` FROM email address.

The SMTPUSER and SMTPPASS parameters are for SMTP authentication.

The ALERTADDRESS parameter is the email address to send notifications to.

# Usage

Note: Some of the information below might be outdated. Accessing endpoints
requires mTLS, it's recommended to place them behind a user facing proxy.

To access prometheus open the following in a browser:
* http://<prometheus-host>:9090
* http://<prometheus-host>:9090/targets/

To access this node's own metrics, visit:
* http://<prometheus-host>:9100/metrics

or run `fetch -o - 'https://127.0.0.1:9100/metrics'`

To see the targets being captured via consul, visit
* http://<prometheus-host>:9090/targets

To access Grafana open the following in a browser and accept the self-signed
certificate:
* https://<prometheus-host>:3000

# Persistent Storage

Persistent storage will be in the ZFS data set zroot/prometheusdata,
available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be
started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust
the `mount-in` command accordingly for the source directory as mounted by
the parent OS.

Do not adjust the image destination mount point at /mnt because Prometheus
is configured to use this directory for data.

# Custom alerts

You can copy-in custom alerts to /mnt/prometheus/alerts before starting
the image.

# Alertmanager

To query the alertmanager config via cli:

    amtool config show --alertmanager.url=http://localhost:9093

To query the alertmanager live alerts via cli:

    amtool -o extended alert --alertmanager.url=http://localhost:9093
