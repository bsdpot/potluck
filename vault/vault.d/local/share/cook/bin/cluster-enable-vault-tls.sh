#!/bin/sh
set -e
export PATH=/usr/local/bin:$PATH
sysrc vault_config=/usr/local/etc/vault.hcl
service vault restart
