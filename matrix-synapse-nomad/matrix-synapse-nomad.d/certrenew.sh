#!/bin/sh
cd /
service nginx stop
/usr/local/sbin/acme.sh --register-account -m "%%SSLEMAIL%%" --server zerossl
/usr/local/sbin/acme.sh --force --issue -d %%DOMAIN%% --standalone
cp -f /.acme.sh/%%DOMAIN%%/* /usr/local/etc/ssl/
service nginx start
service synapse restart
