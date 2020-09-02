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

@@@PARAMETERS TO BE EXPLAINED

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Nomad Job Description Example

It is suggested to mount the jail directory ```/var/db/BackupPC``` from outside as this contains the backup database and settings:

@@@NOMAD EXAMPLE FOLLOWS

