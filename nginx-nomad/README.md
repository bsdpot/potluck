---
author: "Luca Pizzamiglio & Stephan Lichtenauer"
title: NGINX (NOMAD)
summary: This is a NGINX jail that can be deployed via nomad.
tags: ["nginx", "http", "httpd", "web server", "nomad"]
---

# Overview

This is a NGINX jail that can be deployed via ```nomad```.

NGINX is started as blocking task when the jail is started (see ```nginx-nomad+1.sh```)
