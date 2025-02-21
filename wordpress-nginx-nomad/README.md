---
author: "Stephan Lichtenauer"
title: Wordpress on NGINX (Nomad)
summary: This is a Wordpress jail preconfigured with NGINX that can be deployed via nomad.
tags: ["nginx", "http", "wordpress", "blog", "nomad"]
---

# Overview

This is a Wordpress on ```nginx``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

You should mount an outside directory that can (but does not need to) contain a ```wordpress``` installation into ```/usr/local/www/wordpress```. If the directory is empty, ```wordpress``` is installed when the jail is started and it can be configured through the normal ```wordpress``` configuration website that is shown when it is started the first time. That means if the instance is discarded and restarted by ```nomad``` later on, the ```wordpress``` instance that has been installed will be reused.

If there already is a ```wordpress``` installation present, only ```nginx``` is started so that all following updates of Wordpress can be done through the Wordpress web gui itself.

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, no HTTPS configuration is set up in ```nginx``` as it is expected that this is happening in the web proxy.

# Nomad Job Description Example

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 20000
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www", "wordpress"]
        name = "wordpress-example-server"
        port = "http"

         check {
            name     = "check http port potname"
            type     = "tcp"
            port     = "http"
            interval = "60s"
            timeout  = "30s"
          }

          check_restart {
            limit = 5
            grace = "120s"
            ignore_warnings = false
          }
      }

      config {
        image = "https://potluck.honeyguide.net/wordpress-nginx-nomad"
        pot = "wordpress-nginx-nomad-amd64-14_2"
        tag = "2.22.1"
        command = "/usr/local/bin/cook"
        args = [""]
        mount = [
         "/path/to/wordpress:/usr/local/www/wordpress"
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
