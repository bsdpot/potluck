---
author: "Esteban Barrios"
title: MinIO (Nomad)
summary: This is a MinIO jail that can be deployed via nomad.
tags: ["minio", "object storage", "s3 cloud storage", "nomad"]
---

# Overview

This is a MinIO jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

MinIO is started as blocking task when the jail is started (see ```minio-nomad+4.sh```).
The image also is slimmed (see ```minio-nomad+3.sh```)

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Nomad Job Description Example

An easy way to use the jail is to set env variables for ```MINIO_ACCESS_KEY``` and ```MINIO_SECRET_KEY``` on start and mount the /minio directory into the jail (which is referenced by the set-cmd command but can be altered with the command args on the config stanza like ```minio server --config-dir /usr/local/etc/minio $new-path``` ):

```
job "minio-example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    task "task1" {
      driver = "pot"

      service {
        tags = ["minio"]
        name = "minio-example-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/minio-nomad"
        pot = "minio-nomad-amd64-12_1"
        tag = "1.0.0"
        command = "minio"
        args = ["server","--config-dir /usr/local/etc/minio", "/minio"]

       mount = [
         "/mnt/s3/minio/data:/minio"
       ]
        port_map = {
          http = "9000"
        }
      }

      template {
        data = <<EOH
MINIO_ACCESS_KEY="superSecretMinioAccessKey"
MINIO_SECRET_KEY="superSecretMinioSecretKey"
EOH
        destination   = "secrets/file.env"
	env           = true
      }


      resources {
        cpu = 200
        memory = 64

        network {
          mbits = 10
          port "http" {}
        }
      }
    }
  }
}
```
