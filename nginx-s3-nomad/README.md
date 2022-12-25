---
author: "Bretton Vine"
title: NGINX s3 website (Nomad)
summary: This is a jail preconfigured with NGINX configured for s3 that can be deployed via nomad.
tags: ["nginx", "http", "s3", "objectstore", "nomad"]
---

# Overview

This is a ```nginx``` jail that can be deployed via ```nomad```.

You need to pass in the IP addresses and bucket name for s3 objectstore, and `nginx` will serve the files.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, plus frontend ```haproxy``` no HTTPS configuration is specified in ```nginx``` as it is expected that this is happening in the web proxy. HTTPS is merely enabled.

# Installation
To be added.

This image will automatically load-balance between multiple minio servers for a specific bucket.


# Nomad Job Description Example
The following example job uses 3 servers. Simply eliminate the unnecessary options from the args statement for fewer servers.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 28000
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www"]
        name = "nginx-s3-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-s3-nomad"
        pot = "nginx-s3-nomad-amd64-13_1"
        tag = "0.1.1"
        command = "/usr/local/bin/cook"
        args = ["-a","10.0.0.2","-b","10.0.0.3","-c","10.0.0.4","-x","bucketname","-s","yes"]
        copy = [
          "",
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
