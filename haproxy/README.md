---
author: "Bretton Vine"
title: HAProxy
summary: HAProxy is a load-balancing proxy for network traffic
tags: ["load-balance", "proxy", "haproxy"]
---

# Overview

This is a flavour containing the ```haproxy``` load-balancing proxy. You MUST copy in your own ```haproxy.conf``` file, the default setup is hard-coded example.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. If no ```consul``` instance is available at first, make sure it's up within an hour and the certificate renewal process will restart ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/haproxydata zroot/haproxydata```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/haproxydata```
* Copy in the SSH private key for the user on the Vault leader:
  ```pot copy-in -p <jailname> -s /root/sshkey -d /root/sshkey```
* Copy in YOUR haproxy.conf file, and do not change the destination path:
  ```pot copy-in -p <jailname> -s /root/haproxy.conf -d /root/haproxy.conf```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this system> -E PUBLICIP=<Public IP for HAProxy frontend> \
  -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
  -E VAULTSERVER=<IP address vault server> -E VAULTTOKEN=<token> \
  -E SFTPUSER=certuser -E SFTPPASS=<password> -E GOSSIPKEY=<32 byte Base64 key from consul keygen>
  ```

The PUBLICIP parameter is the IP address to use as the front-end to ```haproxy```.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The SFTPUSER and SFTPPASS parameters are for the user on the ```vault``` leader in the VAULTSERVER parameter. You need to copy in the id_rsa from there to the host of this image.

# Usage

To configure ```haproxy```you must copy-in a ```haproxy.conf``` file with your specific front-end and back-end parameters.

This will be copied to ```/usr/local/etc/haproxy.conf``` and used for ```haproxy``` startup.

If you don't copy-in your own ```haproxy.conf``` file, then please take note the default is a round-robin webserver example with hard-coded IP addresses.

# Persistent Storage
Persistent storage will be in the ZFS data set zroot/haproxydata, available inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust the ```mount-in``` command accordingly for the source directory as mounted by the parent OS.

Do not adjust the image destination mount point at /mnt because ```haproxy``` is configured to use this directory for data.
