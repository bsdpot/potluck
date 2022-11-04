---
author: "Luca Pizzamiglio & Stephan Lichtenauer"
title: Nginx (Nomad)
summary: This is a NGINX jail that can be deployed via nomad.
tags: ["nginx", "http", "httpd", "web server", "nomad"]
---

# Overview

This is a NGINX jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

NGINX is started as blocking task when the jail is started (see ```nginx-nomad+4.sh```).
The image also is slimmed (see ```nginx-nomad+3.sh```)

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Nomad Job Description Example

An easy way to use the jail is to copy in a ```nginx.conf``` file on start and mount the www directory into the jail (which needs to be referenced by the ```nginx.conf``` file of course):

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 12000
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www"]
        name = "nginx-example-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-nomad"
        pot = "nginx-nomad-amd64-13_1"
        tag = "1.1.9"
        command = "nginx"
        args = ["-g","'daemon off;'"]

       copy = [
         "/mnt/s3/web/nginx.conf:/usr/local/etc/nginx/nginx.conf",
       ]
       mount = [
         "/mnt/s3/web/www:/mnt"
       ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 200
        memory = 64
      }
    }
  }
}
```
