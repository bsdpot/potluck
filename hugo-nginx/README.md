---
author: "Bretton Vine"
title: Hugo-Nginx 
summary: Hugo is a general-purpose website framework and static site generator
tags: ["www", "website generator", "static site", "automated builds", "hugo", "nginx"]
---

# Overview

This is a flavour containing the ```hugo``` website builder and nginx, a webserver.

This is a minimal config with no SSL configured as this is expected to be handled by a proxy to the image.

It has been put together specifically for use by the https://potluck.honeyguide.net website, however it could be utilised for any site.

You can adjust this flavour and rebuild your own pot image if you have other requirements.

# Disclaimer

It is advised to run this image behind a proxy. The directory permissions on the hugo folder are very permissive to allow a jenkins user in another pot image to do stuff. Run the hugo-nginx and jenkins pot images behind a proxy with access control.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/<sitename> zroot/jaildata_hugo```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created:
  ```pot mount-in -p <jailname> -d /mnt/<sitename> -m /mnt```
* Optionally copy in jenkins user SSH public key:    
  ```pot copy-in -p <jailname> -s /path/to/jenkins/id_rsa.pub -d /root/jenkins.pub```
* Optionally copy in customfile.tgz:    
  ```pot copy-in -p <jailname> -s /path/to/customfile.tgz -d /root/customfile.tgz```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 80:80```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E SERVERNAME=<fqdn> \
  -E IP=<IP of potbuilder VM> -E SITENAME=<site name> \
  -E GITEMAIL=<git user email> -E GITUSER=<git username> \
  [-E CUSTOMDIR=<custom dir inside huge sitename> \
   -E CUSTOMFILE=<1|0 default> -E IMPORTKEYS=<1|0 default> \
   -E THEMEADJUST=<1|0> \
   -E REMOTELOG=<IP syslog-ng server> ]
  ```

SERVERNAME is the fully qualified domain name to configure nginx with.

SITENAME is the name of the hugo site and affects directory naming.

GITEMAIL is the email address to use for a git username.

GITUSER is the git username associated with the email address.

CUSTOMDIR is a custom directory to create inside the hugo installation in SITENAME.

CUSTOMFILE defaults to 0. Set to 1 and copy in your own customfile.tgz which will be extracted to ```/mnt/{SITENAME}/```. This would be a custom config.toml, static microblog posts or about.md pages and images for static dir.

IMPORTKEYS defaults to 0. Set to 1 to add the copied in pubkey to authenticated_keys.
Copy in the applicable id_rsa.pub as part of the pot setup and start process.

THEMEADJUST defaults to 0 and makes no changes to the ```kiss-em``` theme in use. If set to 1 will make changes specific to http://potluck.honeyguide.net.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

# Usage
Start hugo manually (not necessary):
```
cd /mnt/<sitename> && hugo
```

To access ```hugo```:
* http://<hugo-host>

The default site is blank.

# customfile.tgz

If you wish to include a custom setup for hugo, you can create a file ```customfile.tgz``` with the following folder structure:

```
./config.toml
./static
./static/mylogo.png
./content/info.md
./content/micro/news.md
./content/micro/about.md
```

Make sure to copy-in to /root/customfile.tgz and set ```-E CUSTOMFILE=1``` in the parameters. 

# Persistent storage

To use persistent storage make sure to mount-in a pre-configured data set to /mnt/<sitename>. 
