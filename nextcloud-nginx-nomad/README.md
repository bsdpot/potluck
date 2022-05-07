---
author: "Bretton Vine"
title: Nextcloud on NGINX (Nomad)
summary: This is a Nextcloud jail preconfigured with NGINX that can be deployed via nomad.
tags: ["nginx", "http", "nextcloud", "documents", "nomad"]
---

# Overview

This is a Nextcloud on ```nginx``` jail that can be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

You should mount an outside directory that can (but does not need to) contain a ```nextcloud``` installation into ```/usr/local/www/nextcloud```. If the directory is empty, ```nextcloud``` is installed when the jail is started and it can be configured through the normal ```nextcloud``` configuration website that is shown when it is started the first time. That means if the instance is discarded and restarted by ```nomad``` later on, the ```nextcloud``` instance that has been installed will be reused.

If there already is a ```nextcloud``` installation present, only ```nginx``` is started so that all following updates of Nextcloud can be done through the web gui itself.

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, no HTTPS configuration is set up in ```nginx``` as it is expected that this is happening in the web proxy.

# ZFS datasets
Make sure to create the ZFS datasets beforehand, adapt to your data set naming convention:
```
zfs create data/pot
zfs create data/pot/jaildata_nextcloud
zfs create data/pot/jaildata_nextcloud_files
```

`jaildata_nextcloud` is where the nextcloud files are installed and is mounted to `/usr/local/www/nextcloud/` inside the image.

`jaildata_nextcloud_files` is where the files will be kept, and is mounted to `/mnt/filestore` or similar inside the image.

# Installation
When you first run the image you'll need to setup Nextcloud via the web interface.

Make sure to specify `/mnt/filestore` or similar for DATADIR parameter (-d) in the web interface for Nextcloud setup too by clicking the dropdown for database and storage.

# Nomad Job Description Example

```
job "nextcloud" {
  datacenters = ["datacentre"]
  type        = "service"

  group "group1" {
    count = 1 

    network {
      port "http" {
        static = 20900
      }
    }

    task "nextcloud1" {
      driver = "pot"

      restart {      
        attempts = 3      
        delay    = "30s"    
      }

      service {
        tags = ["nginx", "www", "nextcloud"]
        name = "nextcloud-server"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
          check_restart {
            limit = 0
            grace = "120s"
            ignore_warnings = false
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nextcloud-nginx-nomad"
        pot = "nextcloud-nginx-nomad-amd64-13_0"
        tag = "0.12"
        command = "/usr/local/bin/cook"
        args = ["-d","/mnt/filestore"]
        mount = [
         "/mnt/data/pot/jaildata_nextcloud/:/usr/local/www/nextcloud",
         "/mnt/data/pot/jaildata_nextcloud_extra/:/mnt/filestore",
        ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 1000
        memory = 1024
      }
    }
  }
}
```

# Warnings

This is a very large pot image. The nomad job will timeout on first run as `pot` takes a while to download the image and add it.

The image boots with https enabled in nginx. You will need a frontend proxy like `haproxy` or similar to handle the redirect from a domain name, with SSL, to the internal nomad host and port configured in job file. A valid digital certificate would be useful too.