---
author: "Bretton Vine"
title: FreeBSD-Potluck
summary: FreeBSD-Potluck is a single pot base image for building layered images.
tags: ["base image", "layers", "testing"]
---

# Overview

This flavour is a bare base pot image. Just FreeBSD-13.2.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system>
  ```
* Start the jail

## Required Paramaters
The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

# Usage

This is a base image to be used for layered pot images. Documentation pending.
