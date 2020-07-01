---
author: "Stephan Lichtenauer"
title: JITSI MEET (NOMAD)
summary: This is a JITSI MEET jail that can be deployed via nomad.
tags: ["jitsi", "jitsi-meet", "video conference", "nomad"]
---

# Overview

This is a complete ```jitsi-meet``` installation in one jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

The jail configures itself on the first start for your environment (see notes below).

NGINX is started as blocking task when the jail is started, all other services are started as services.

Deploying the image or flavour should be quite straight forward and not take more than a few minutes:

# Installation

* Create your local jail from the image or the flavour files as with every other jail (see documentation below).
* Adjust to your environment: ```pot set-env -p test -E DOMAINNAME=<yourdomain> -E PUBLICIP=<yourpublicip> -E PRIVATEIP=<yourpotip>```
  * <yourdomain> should be the FQDN of your server that users can connect to in their web browser, e.g. jitsi.honeyguide.net
  * <yourpublicip> is the public IP address associated with the server behind this domain name
  * <yourpotip> is the IP address that has been created by '''pot''' when importing/creating the jail (see the output of ```pot import``` or ```pot create```, e.g. 10.192.0.3.
* (You can skip that now, see workaround below instead) Forward the ports: ```pot export-ports -p test -e 80:80 -e 443:443 -e 10000:10000 -e 4443:4443```.
* Start the pot: ```pot start <yourpotname>```. On the first run the jail will configure itself and start the services. If it would not be for the following one step, you could now use your video conference platform.

**Workaround for missing UDP port forwarding:**
```pot``` at the moment only forwards TCP ports, not UDP ports. Therefore you need to fix the port forward *each time you start the jail* manually with a command like this:

```bash
echo "
rdr pass on em0 inet proto tcp from any to <yourhostip> port = http -> <yourpotip> port 80
rdr pass on em0 inet proto tcp from any to <yourhostip> port = https -> <yourpotip>  port 443
rdr pass on em0 inet proto udp from any to <yourhostip> port = 10000 -> <yourpotip>  port 10000
rdr pass on em0 inet proto tcp from any to <yourhostip> port = 4443 -> <yourpotip>  port 4443
" | pfctl -a pot-rdr/<yourpotname> -f -
```
<yourhostip> is the IP address users will connect to, <yourpotip> is the ```pot``` generated IP address (e.g. 10.192.0.3), <yourpotname> is the name you have given your jail.


For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

