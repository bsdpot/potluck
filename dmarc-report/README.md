---
author: "Bretton Vine"
title: DMARC-report
summary: DMARC-report will produce a graphical report for an IMAP folder with DMARC reports
tags: ["dmarc", "mail", "monitoring"]
---

# Overview

This flavour contains a local implementation of [parsedmarc](https://pypi.org/project/parsedmarc/).

`parsedmarc` will produce CSV/JSON output from the relevant mailbox folder in the destination folder selected for /mnt.

This information can be submitted to the local `zincsearch` instance, a low footprint, non-java, `elasticsearch` clone.

It is currently expected that this jail will run on an internal IP with no remote access.

The display of the report using `zincsearch` data is pending.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Warnings

The `parsedmarc` process can take up to 30min to complete with only a few hundred mails in your dmarc folder on a first run.

There is no progress indicator when complete. When your dmarc folder empties, the initial run is complete, and the messages go to the Archive folder.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in persistent storage
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
    -E IMAPSERVER=<mail host> \
    -E IMAPUSER=<imap username> \
    -E IMAPPASS=<imap password> \
    -E IMAPFOLDER=<imap folder with dmarc reports> \
    -E OUTPUTFOLDER=<name of folder to create in /mnt/> \
    -E ZINCUSER=<zincsearch admin user> \
    -E ZINCPASS=<zincsearch admin pass> \
    -E ZINCDATA=<path to store zincsearch files, default /mnt/zinc/data> \
    [ -E ZINCPORT=<zincsearch port, default 4080> ] \
    [ -E REMOTELOG=<IP address> ]
  ```
* Start the jail

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The IMAPSERVER parameter is the IP address or hostname of the IMAP server. It defaults to port 993 and SSL.

The IMAP user credentials are set with IMAPUSER and IMAPPASS.

The IMAPFOLDER parameter is the mail folder with the DMARC reports as attachments. 

The OUTPUTFOLDER parameter is the folder to create in /mnt, which should be mounted in as persistent storage.

The ZINCUSER and ZINCPASS parameters set the `zincsearch` admin user and password.

The ZINCDATA parameter is the directory to save `zincsearch` data files. Defaults to `/mnt/zinc/data`.

## Optional Parameters

The ZINCPORT parameter is the port to make `zincsearch` available on. Defaults to `4080`.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

We recommend creating a dedicated mailbox folder for DMARC reports and filtering those mails to it. Then configure this image to use that mail folder.

This development version simply sets up `parsedmarc` and runs the python process to generate JSON and CSV output from a mailbox.

It still needs a way to store the reports long term, and show pretty charts. Possibly `elasticsearch` and `kibana` or something lighter.

Note: there is very little feedback that process a mailbox has happened. Check the folders under `Archive` called `Aggregate`, `Foresic`, and `Invalid`. You might need to subscribe to the folders in an IMAP client to see. When mails are processed from the identified `dmarc` mail folder, they are transferred to the `Archive` subfolders.
