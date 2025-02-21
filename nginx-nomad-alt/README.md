---
author: "Bretton Vine"
title: NGINX alt website (Nomad)
summary: This is a jail preconfigured with NGINX and PHP that can be deployed via nomad.
tags: ["nginx", "http", "php", "nomad"]
---

# Overview

This is a ```nginx``` jail that can be deployed via ```nomad```.

You need to create persistent storage, with a subdirectory www. Place an index.php or index.html file, or whole website, in the www directory.

Mount in the persistant storage with www subdirectory to /usr/local/www/stdwebsite in the job file as below.

```nginx``` will serve files from this location by default.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, plus frontend ```haproxy``` no HTTPS configuration is specified in ```nginx``` as it is expected that this is happening in the web proxy. HTTPS is merely enabled.

# Installation

# Options
You can pass in parameters to the image to set variables.

-E SERVERNAME or `-s servername`.

# Nomad Job File Samples

The following is an example job file:

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 25080
      }
    }

    task "simpleweb1" {
      driver = "pot"

      service {
        tags = ["nginx", "simpleweb"]
        name = "nginx-alt-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-nomad-alt"
        pot = "nginx-nomad-alt-amd64-14_2"
        tag = "0.23.1"
        command = "/usr/local/bin/cook"
        args = ["-s","servername"]
        mount = [
          "/mnt/data/jaildata/stdwebsite/www:/usr/local/www/stdwebsite",
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

End