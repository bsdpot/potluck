---
author: "Bretton Vine"
title: Hugo-Nginx-ALT
summary: Hugo is a general-purpose website framework and static site generator
tags: ["www", "website generator", "static site", "automated builds", "hugo", "nginx"]
---

# Overview

This is an alternate flavour containing the ```hugo``` website builder and nginx, a webserver.

It will take in sources for data and themes and generate a site. It can also send the site content to an S3 host.

This is a minimal config with no SSL configured as this is expected to be handled by a reverse proxy.

You can adjust this flavour and rebuild your own pot image if you have other requirements.

# Disclaimer

It is advised to run this image behind a proxy. The directory permissions on the hugo folder are very permissive. Run the hugo-nginx-alt pot images behind a proxy with access control.

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/<sitename> zroot/jaildata/hugoalt```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created:
  ```pot mount-in -p <jailname> -d /mnt/<sitename> -m /mnt```
* Optionally copy in customfile.tgz:
  ```pot copy-in -p <jailname> -s /path/to/customfile.tgz -d /root/customfile.tgz```
* Optionally copy in your own customscript.sh
  ```pot copy-in -p <jailname> -s /path/to/customscript.sh -d /root/customscript.sh```
* Optionally copy in SSH private key for custom gitserver ssh access. Make sure destination is `/root/sshkey`:
  ```pot copy-in -p <jailname> -s /path/to/id_rsa -d /root/sshkey```
* Optionally export the ports after creating the jail:
  ```pot export-ports -p <jailname> -e 80:80```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
  -E NODENAME=name \
  -E DATACENTER=datacenter \
  -E CONSULSERVERS=<comma-deliminated list of consul servers> \
  -E SERVERNAME=<fqdn> \
  -E DOMAINNAME=<baseURL value> \
  -E IP=<IP address> \
  -E SITENAME=<site name> \
  -E GITEMAIL=<git user email> \
  -E GITUSER=<git username> \
  -E THEMESRC=<git url> \
  -E THEMENAME=<name of theme, will become directory name> \
  [ -E CUSTOMDIR=<custom dir inside huge sitename> ] \
  [ -E CUSTOMFILE=1 ] \
  [ -E CONTENTSRC=<git url> ] \
  [ -E GITPORT=<ssh access port for custom git server> ] \
  [ -E GITHOST=<IP address of custom gitserver> ] \
  [ -E MYTITLE="site title in quotes" ] \
  [ -E MYLANG=<language code> ] \
  [ -E BUCKETHOST=<ip or hostname S3 host> ] \
  [ -E BUCKETUSER=<s3 username> ] \
  [ -E BUCKETPASS=<s3 password> ] \
  [ -E BUCKETNAME=<name of bucket> ] \
  [ -E REMOTELOG=<IP syslog-ng server> ]
  ```

The NODENAME parameter is the name of the node.

The DATACENTER parameter is the name of the datacenter. The REGION parameter is to set "east" or "west" or "global" (default).

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The SERVERNAME parameter is the fully qualified domain name to configure nginx with.

The DOMAINNAME parameter is the domain name of the final destination, or baseURL for hugo. Include `http://` or `https://`.

The IP parameter is the IP address of the pot image.

The SITENAME parameter is the name of the hugo site and affects directory naming.

The GITEMAIL parameter is the email address to use for a git username.

The GITUSER parameter is the git username associated with the email address.

The THEMESRC parameter is the URL to the theme git source.

The THEMENAME parameter is the name of the theme. This will become a directory name so no spaces or punctuation.

The optional CUSTOMDIR parameter is a custom directory to create inside the hugo installation in SITENAME.

The optional CUSTOMFILE parameter, if set to 1, will copy in your own customfile.tgz which will be extracted to ```/mnt/{SITENAME}/```. This would be a custom ```hugo.yaml```, static microblog posts or about.md pages and images for static dir.

The optional CONTENTSRC parameter is the HTTP url of a github source with custom content pages and static files, or `git@hostname:/path` for a custom git server.

The optional GITPORT parameter is the SSH port for a custom git server instance. Set this is passing in `git@hostname:/path` for CONTENTSRC.

The optional GITHOST parameter is the hostname or IP address of a custom git server instance. Set this is passing in `git@hostname:/path` for CONTENTSRC. Make sure to copy in the private SSH key for the user in `authorized_keys` on git server to `/root/sshkey`.

The optional MYTITLE parameter is the site title. A default title will be set if not enabled.

The optional MYLANG parameter is the language code. Defaults to ```en``` over the ```hugo``` default ```en-us```.

The optional parameters BUCKETHOST, BUCKETUSER, BUCKETPASS and BUCKETNAME refer to credentials for minio-client to perform sync of HTML files to a bucket.

The optional REMOTELOG parameter is for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

# Usage
Start hugo manually (not necessary):
```
cd /var/db/SITENAME && hugo
```

To access ```hugo```:
* http://hugo-host-name

The default site is blank.

# customfile.tgz

If you wish to include a custom setup for hugo, you can create a file ```customfile.tgz``` with the following folder structure:

```
./config.toml
./assets
./static
./static/mylogo.png
./content/info.md
./content/micro/news.md
./content/micro/about.md
```

Make sure to copy-in to /root/customfile.tgz and set ```-E CUSTOMFILE=1``` in the parameters.

# customfile.sh.example

There is an example `customscript.sh` you can copy in to `/root/customscript.sh`.

Check out the file `customscript.sh.example` in the git folder.

# Persistent storage

Persistent storage is not used in this version of the hugo pot image. To update re-run the pot image and rebuild the site.
