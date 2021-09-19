---
author: "Bretton Vine"
title: Nextcloud on NGINX (Nomad)
summary: This is a Nextcloud jail preconfigured with NGINX that can be deployed via nomad.
tags: ["nginx", "http", "nextcloud", "documents", "nomad"]
---

# Overview

This is a Nextcloud on ```nginx``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

You should mount an outside directory that can (but does not need to) contain a ```nextcloud``` installation into ```/usr/local/www/nextcloud```. If the directory is empty, ```nextcloud``` is installed when the jail is started and it can be configured through the normal ```nextcloud``` configuration website that is shown when it is started the first time. That means if the instance is discarded and restarted by ```nomad``` later on, the ```nextcloud``` instance that has been installed will be reused.

If there already is a ```nextcloud``` installation present, only ```nginx``` is started so that all following updates of Nextcloud can be done through the web gui itself.

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, no HTTPS configuration is set up in ```nginx``` as it is expected that this is happening in the web proxy.

# ZFS datasets
Make sure to create the ZFS datasets beforehand, adapt to your data set naming convention:
```
zfs create data/pot
zfs create data/pot/jaildata_nextcloud
```

# Nomad Job Description Example

```
job "nextcloud" {
  datacenters = ["datacentre"]
  type        = "service"

  group "group1" {
    count = 1 

    task "www1" {
      driver = "pot"

      restart {      
        attempts = 3      
        delay    = "30s"    
      }

      service {
        tags = ["nginx", "www", "nextcloud"]
        name = "nextcloud-server
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
        tag = "0.1"
        command = "/usr/local/bin/cook"
        args = [""]

        mount = [
         "/mnt/data/pot/jaildata_nextcloud/:/usr/local/www/nextcloud"
        ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 1000
        memory = 1024

        network {
          mbits = 75
          port "http" {
            static = 20888
          }
        }
      }
    }
  }
}
```
