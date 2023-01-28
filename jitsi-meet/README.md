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
  ```sudo pot clone -P jitsi-meet-amd64-13_1_0_3_6 -p jitsi-meet -N alias -i "em0|10.10.10.11"```
* Copy in any supporting files such as image file for customisation
  ```sudo pot copy-in -p <clonejailname> -s <source image> -d /usr/local/www/jitsi-meet/images/<destination filename>```
* Adjust to your environment:
  ```sudo pot set-env -p <clonejailname> -E NODENAME=<name> \
    -E DATACENTER=<datacentername> \
    -E IP=<IP address of this nomad instance> \
    -E NODENAME=<an internal name for image> \
    -E CONSULSERVERS=<'"list", "of", "consul", "IPs"'> \
    -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
    -E DOMAIN=<FQDN for host> \
    -E EMAIL=<email address for letsencrypt setup> \
    -E PUBLICIP=<yourpublicip> \
    [ -E IMAGE="filename.svg" ] \
    [ -E LINK="https://full.url" ] \
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

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name of the `jitsi-meet` instance.

The EMAIL parameter is the email address to use for letsencrypt registration. SSL certificates are mandatory, modern browsers won't open camera or microphone unless SSL enabled.

The PUBLIC IP parameter is the public facing IP address which users connect to.

## Optional Parameters

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

The IMAGE parameter is the filename of an image copied in to `/usr/local/www/jitsi-meet/images/{filename}` if using a custom logo image. You must copy this file in as part of the steps above.

The LINK parameter is the full URL with `https://full.url/path` which someone will go to when clicking the custom logo image.

