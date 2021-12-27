---
author: "Bretton Vine"
title: Nginx-rsync-ssh
summary: Custom image with nginx, acme.sh, openssl, rsync, ssh requiring copied-in config files
tags: ["nginx", "rsync", "development image", "custom image"]
---

# Overview

This is a development flavour containing the ```nginx``` webserver, along with ```acme.sh```, ```openssl```, ```rsync``` and ssh.

It has been put together specifically for use in custom images and you MUST copy in files and set the parameter to 1 to enable:
- sshd_config
- authorized_keys
- nginx.conf
- rsyncd.conf
- setup.sh
- postsetup.sh

You can adjust this flavour and rebuild your own pot image if you have other requirements.

# Installation

* Create a ZFS data set on the parent system beforehand, for example:
  ```zfs create -o mountpoint=/mnt/<name> zroot/jaildata_<name>```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created:    
  ```pot mount-in -p <jailname> -d <src> -m <dest>```
* Optionally copy in SSH authorized_keys file:    
  ```pot copy-in -p <jailname> -s /path/to/authorized_keys -d /root/authorized_keys_in```
* Optionally copy in SSH sshd_config file:    
  ```pot copy-in -p <jailname> -s /path/to/sshd_config -d /root/sshd_config_in```
* Optionally copy in nginx.conf file:    
  ```pot copy-in -p <jailname> -s /path/to/nginx.conf -d /root/nginx.conf```
* Optionally copy in rsyncd.conf file:    
  ```pot copy-in -p <jailname> -s /path/to/rsyncd.conf -d /root/rsyncd.conf```
* Optionally copy in setup.sh file for early commands to run:    
  ```pot copy-in -p <jailname> -s /path/to/setup.sh -d /root/setup.sh```
* Optionally copy in postsetup.sh file for late commands to run after services are setup:    
  ```pot copy-in -p <jailname> -s /path/to/postsetup.sh -d /root/postsetup.sh```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 80:80```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> \
   -E SETUPSCRIPT=<1 | 0 default> \
   -E IMPORTAUTHKEY=<1 | 0 default> \
   -E IMPORTSSH=<1 | 0 default> \
   -E IMPORTNGINX=<1 | 0 default> \
   -E IMPORTRSYNC=<1 | 0 default> \
   -E POSTSCRIPT=<1 | 0 default>
  ```

SETUPSCRIPT will run copied-in ```/root/setup.sh``` when set to 1. You can set custom commands here like creating directories needed for nginx.

IMPORTAUTHKEY will add copied-in ```/root/authorized_keys_in``` to ```/root/.ssh/authorized_keys``` when set to 1.

IMPORTSSH will add copied-in ```/root/sshd_config_in``` to ```/etc/sshd/sshd_config``` when set to 1. You can specify a custom sshd_config this way.

IMPORTNGINX will add copied-in ```/root/nginx.conf``` to ```/usr/local/etc/nginx/nginx.conf``` when set to 1. You can specify a custom nginx.conf this way.

IMPORTRSYNC will add copied-in ```/root/rsyncd.conf``` to ```/usr/local/etc/rsync/rsyncd.conf``` when set to 1. You can specify a custom rsyncd.conf this way. 

POSTSCRIPT will run copied-in ```/root/postsetup.sh``` when set to 1. You can add additional commands to run to a script ```postsetup.sh``` here, which run AFTER all the services have been setup.

# Usage
To access ```nginx```:
* http://hostname

# Persistent storage

To use persistent storage make sure to mount-in a pre-configured data set to the applicable directory. 
