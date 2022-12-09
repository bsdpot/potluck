---
author: "Bretton Vine, Stephan Lichtenauer"
title: Jitsi Meet
summary: This is a complete JITSI MEET instance that can be deployed like a regular pot jail.
tags: ["jitsi", "jitsi-meet", "video conference"]
---

# Overview

This is a complete ```jitsi-meet``` installation in one jail that can be started with ```pot```.

The jail configures itself on the first start for your environment (see notes below), for details about how to run ```jitsi-meet``` in a FreeBSD jail in general, see [this blog post](https://honeyguide.eu/posts/jitsi-freebsd/).

Deploying the image or flavour should be quite straight forward and not take more than a few minutes.

# Installation

* Create your local jail from the image or the flavour files.
* This jail does not work with a public bridge, so clone it to use an IP address directly on your host:
  ```sudo pot clone -P <nameofimportedjail> -p <clonejailname> -N alias -i "<interface>|<ipaddress>"```
  e.g.
  ```sudo pot clone -P jitsi-meet-amd64-13_1_0_1_1 -p jitsi-meet -N alias -i "em0|10.10.10.11"```
* Adjust to your environment:
  ```sudo pot set-env -p <clonejailname> -E NODENAME=<name> \
    -E DATACENTER=<datacentername> \
    -E IP=<IP address of this nomad instance> \
    -E CONSULSERVERS=<'"list", "of", "consul", "IPs"'> \
    -E DOMAIN=<FQDN for host> \
    -E EMAIL=<email address for letsencrypt setup> \
    -E PUBLICIP=<yourpublicip> \
    [ -E GOSSIPKEY="<32 byte Base64 key from consul keygen>"] \
    [ -E REMOTELOG="<IP syslog-ng server>" ]```
* Forward the needed ports: ```pot export-ports -p <yourjailname> -e 80:80 -e 443:443 -e 10000:10000 -e 4443:4443``` with &lt;yourjailname&gt; again being the name of your newly created/imported jail.
* Start the pot: ```pot start <yourjailname>```. On the first run the jail will configure itself and start the services.
  If it would not be for the following one workaround step, you could now use your video conference platform.

**Workaround for missing UDP port forwarding:**
```pot``` at the moment only forwards TCP ports, not UDP ports. Therefore you need to fix the port forward *each time you start the jail* manually with a command like this:

```bash
echo "
rdr pass on em0 inet proto tcp from any to <yourhostip> port = http -> <yourpotip> port 80
rdr pass on em0 inet proto tcp from any to <yourhostip> port = https -> <yourpotip>  port 443
rdr pass on em0 inet proto udp from any to <yourhostip> port = 10000 -> <yourpotip>  port 10000
rdr pass on em0 inet proto tcp from any to <yourhostip> port = 4443 -> <yourpotip>  port 4443
" | pfctl -a pot-rdr/<yourjailname> -f -
```
&lt;yourhostip&gt; is the IP address users will connect to, &lt;yourpotip&gt; is the ```pot``` generated IP address (e.g. 10.192.0.3), &lt;yourjailname&gt; is the name you have given your jail.

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

