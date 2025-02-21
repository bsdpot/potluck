---
author: "Stephan Lichtenauer"
title: BackupPC (Nomad)
summary: This is a BackupPC server jail that can be deployed via nomad.
tags: ["backuppc", "backup", "nomad"]
---

# Overview

This is a BackupPC jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

The storage directory is in ```/var/db/BackupPC```.
It is suggested that this directory is mounted from outside the jail when it is run as a ```nomad``` task so that it is persistent (see example below).

The admin interface can be accessed via web browser through port 80.

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

| Environment      | cook parameter     | Content      |
| :--------------- | :----------------: | :-----------|
| PASSWORD         | -p              | Password for user ```admin``` in the web interface |

**Note: The jail does not yet send any BackupPC emails. Flavour patches for this or for making the configuration more persistent (see job description below) are welcome :) ...**

# Nomad Job Description Example

It is suggested to mount the jail directories ```/var/db/BackupPC``` and ```/usr/local/etc/backuppc/pc``` from outside as these contain the backup database and the host specific settings which both probably should be persistent.

Also, it is suggested to copy in the BackupPC ```hosts``` file (as this will otherwise be recreated on each job scheduling, so also edit this file by hand outside of the jail and *not* via the admin GUI as the changes otherwise will be lost when the jail is rescheduled by ```nomad```). The main BackupPC configuration will be recreated as well, so store configuration in your per host settings that are stored in the mounted in directory ```/usr/local/etc/backuppc/pc```.

Last not least, if you use ```ssh``` to access clients, you probably also want to copy your private/public key pair to ```/home/backuppc/.ssh``` so the BackupPC server can access your clients.

```
job "backuppc" {
  datacenters = ["mydc"]
  type        = "service"

  group "group1" {
    count = 1

    task "www1" {
      driver = "pot"

      service {
        tags = ["backuppc", "www"]
        name = "backuppc"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
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
        image = "https://potluck.honeyguide.net/backuppc-nomad"
        pot = "backuppc-nomad-amd64-14_2"
        tag = "1.22.1"
        command = "/usr/local/bin/cook"
        args = ["-p","myadminpassword"]
        mount = [
          "/mnt/backupdb:/var/db/BackupPC",
          "/mnt/etc_pc:/usr/local/etc/backuppc/pc"
        ]
        copy = [
          "/mnt/hosts:/usr/local/etc/backuppc/hosts",
          "/mnt/id_rsa:/home/backuppc/.ssh/id_rsa",
          "/mnt/id_rsa.pub:/home/backuppc/.ssh/id_rsa.pub"
        ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 500
        memory = 512

        network {
          mbits = 50
          port "http" {}
        }
      }
    }
  }
}
```
