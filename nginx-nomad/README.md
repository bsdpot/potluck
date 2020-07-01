---
author: "Luca Pizzamiglio & Stephan Lichtenauer"
title: Nginx (Nomad)
summary: This is a NGINX jail that can be deployed via nomad.
tags: ["nginx", "http", "httpd", "web server", "nomad"]
---

# Overview

This is a NGINX jail that can be started with ```pot```but it can also be deployed via ```nomad```.

NGINX is started as blocking task when the jail is started (see ```nginx-nomad+4.sh```).
The image also is slimmed (see ```nginx-nomad+3.sh```)

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).
