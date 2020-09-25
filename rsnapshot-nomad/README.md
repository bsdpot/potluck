---
author: "Stephan Lichtenauer"
title: Rsnapshot Server (Nomad)
summary: This is a Rsnapshot jail that can be used as backup server and be deployed via nomad.
tags: ["rsnapshot", "rsync", "backup", "nomad"]
---

# Overview

This is a ```rsnapshot``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

| Environment      | cook parameter     | Content      |
| :--------------- | :----------------: | :-----------|
| ALPHA       | -a              | ```/etc/crontab``` frequency for alpha backup plan |
| BETA       | -b              | Optional: ```/etc/crontab``` frequency for beta backup plan |
| DELTA       | -d              | Optional: ```/etc/crontab``` frequency for delta backup plan |
| GAMMA       | -g              | Optional: ```/etc/crontab``` frequency for gamma backup plan |

The frequency is given in the standard cron entry format, e.g. "0 */4 * * *" or "40 23 * * 6".


# Nomad Job Description Example

It is suggested to mount the jail directory ```/.snapshots``` from outside as it contains the backups (or any other backup directory that you define in your configuration below).

Also, you should copy in the ```rsnapshot.conf``` file to ```/usr/local/etc``` with your configuration settings. 

Last not least, since you probably will use ssh to access clients, you also want to copy your private/public key pair to ```/root/.ssh``` so the BackupPC server can access your clients.

Assuming that you don't copy in a ```known_hosts``` file, ```ssh``` would prompt on the first connection attempt to your clients that are to be backed up for your confirmation to add the unknown ```ssh``` host keys to your ```known_hosts``` file within the jail, a prompt that you won't see of course as the job is run inside the jail via ```cron```. Therefore, it is suggested that you add ```ssh_args        -o "StrictHostKeyChecking=no"``` to your ```rsnapshot.conf``` to suppress the prompt and make sure the backup runs correctly in batch mode.

Example with passing parameters to the ```cook``` script:

```
job "rsnapshot" {
  datacenters = ["mydc"]
  type        = "service"

  group "group1" {
    count = 1 

    task "backupmx1" {
      driver = "pot"

      config {
        image = "https://potluck.honeyguide.net/rsnapshot-nomad"
        pot = "rsnapshot-nomad-amd64-12_1"
        tag = "1.0"
        command = "/usr/local/bin/cook"
        args = ["-a","\"40 23 * * 6\""]
        mount = [
          "/mnt/backups:/.snapshots"
        ]
        copy = [
          "/mnt/rsnapshot.conf:/usr/local/etc/rsnapshot.conf"
          "/mnt/id_rsa:/root/.ssh/id_rsa",
          "/mnt/id_rsa.pub:/root/.ssh/id_rsa.pub"
        ]
      }

      resources {
        cpu = 500
        memory = 1024
      }
    }
  }
}
```
