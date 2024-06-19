---
author: "Bretton Vine"
title: Smokeping 
summary: Smokeping is a network latency monitor
tags: ["smokeping", "network", "monitoring"]
---

# Overview

This is a development flavour containing the ```smokeping``` network latency monitoring tool.

By default it will monitor predefined hosts, but you can copy in a replacement `smokeping` config file with your own hosts configured under "targets". 

# Installation

* Create a ZFS dataset on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/smokepingdata zroot/smokepingdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS dataset you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/smokepingdata```
* Optionally copy in a custom `smokeping` config file. Make sure the destination file is `/root/config.in`
  ```pot copy-in -p <jailname> -s /path/to/smokeping/config -d /root/config.in```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> \
  -E ALERTEMAIL=<address to send alerts to> \
  -E EMAIL=<from email> \
  -E HOSTNAME=<hostname of this system> \
  -E IP=<IP address of this system> \
  -E MAILHOST=<ip of mail host> \
  -E NODENAME=<nodename> \
  [ -E ALTNETWORK=<any value is true> ]
  ```

You must pass in the following parameters, even if copying in a custom config file. The image expects a value set for IP and NODENAME, and dummy data can be set for the others if using custom config file.

ALERTEMAIL is the email address to send alerts to. If passing as `cook` flag use `-a email@addy.com`.

EMAIL is the owner address, and from address, for email notices. If passing as `cook` flag use `-e email2@addy.com`.

HOSTNAME is the FQDN which will be used to access such as latency.yourhost.com. If passing as `cook` flag use `-h latency.yourhost.com`.

IP is this node's IP address. If passing as `cook` flag use `-i 1.2.3.4`.

MAILHOST is the hostname or IP address of a mail server which will accept unauthenticated mail from this system. If passing as `cook` flag use `-m smtp.yourhost.com`.

NODENAME is the name of this node. If passing as `cook` flag use `-n smokeping`.

The optional parameter ALTNETWORK is a gateway IP address. Do not use this if you don't know what it's for. If passing as `cook` flag use something like `-z 172.17.0.1`.

# Custom Targets
You can create a custom `smokeping` config file in the following format
```
*** General ***

owner    = Peter Random
contact  = some@address.nowhere
mailhost = my.mail.host
sendmail = /usr/sbin/sendmail
# NOTE: do not put the Image Cache below cgi-bin
# since all files under cgi-bin will be executed ... this is not
# good for images.
imgcache = /mnt/smokeping/imagecache
imgurl   = cache
datadir  = /mnt/smokeping/data
piddir  = /mnt/smokeping/run
cgiurl   = http://some.url/smokeping.cgi
smokemail = /usr/local/etc/smokeping/smokemail.sample
tmail = /usr/local/etc/smokeping/tmail.sample
# specify this to get syslog logging
syslogfacility = local0
# each probe is now run in its own process
# disable this to revert to the old behaviour
# concurrentprobes = no

*** Alerts ***
to = alertee@address.somewhere
from = smokealert@company.xy

+someloss
type = loss
# in percent
pattern = >0%,*12*,>0%,*12*,>0%
comment = loss 3 times  in a row

*** Database ***

step     = 300
pings    = 20

# consfn mrhb steps total

AVERAGE  0.5   1  28800
AVERAGE  0.5  12   9600
    MIN  0.5  12   9600
    MAX  0.5  12   9600
AVERAGE  0.5 144   2400
    MAX  0.5 144   2400
    MIN  0.5 144   2400

*** Presentation ***

template = /usr/local/etc/smokeping/basepage.html.sample
htmltitle = yes
graphborders = no

+ charts

menu = Charts
title = The most interesting destinations

++ stddev
sorter = StdDev(entries=>4)
title = Top Standard Deviation
menu = Std Deviation
format = Standard Deviation %f

++ max
sorter = Max(entries=>5)
title = Top Max Roundtrip Time
menu = by Max
format = Max Roundtrip Time %f seconds

++ loss
sorter = Loss(entries=>5)
title = Top Packet Loss
menu = Loss
format = Packets Lost %f

++ median
sorter = Median(entries=>5)
title = Top Median Roundtrip Time
menu = by Median
format = Median RTT %f seconds

+ overview 

width = 600
height = 50
range = 10h

+ detail

width = 600
height = 200
unison_tolerance = 2

"Last 3 Hours"    3h
"Last 30 Hours"   30h
"Last 10 Days"    10d
"Last 360 Days"   360d

*** Probes ***

+ FPing

binary = /usr/local/sbin/fping

*** Targets ***

probe = FPing

menu = Top
title = Network Latency Grapher
remark = Welcome to the SmokePing. \
         Here you will learn all about the latency of our network.

+TopLevel
menu = Top Level
title = top level categories

++News
menu = News
title = New hosts

+++BBC
menu = BBC
title = BBC
host = bbc.com

+++ CNBC
menu = CNBC
title = CNBC
host = cnbc.com

+++CNN
menu = CNN
title = CNN
host = cnn.com

++Search
menu = Search
title = Search sites

+++Bing
menu = Bing
title = Bing Search
host = bing.com

+++Google
menu = Google
title = Google Search
host = google.com

+++ Youtube
menu = Youtube
title = Youtube
host = youtube.com

```

When copying in a custom config file to the pot image, make sure the destination is `/root/config.in`. This is what the image is expecting.

# Usage

To access ```spokeping```:
* http://<smokeping-host>/smokeping

# Persistent Storage
Persistent storage will be in the ZFS dataset zroot/smokepingdata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS dataset, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because `smokeping` is configured to use this directory for data.
