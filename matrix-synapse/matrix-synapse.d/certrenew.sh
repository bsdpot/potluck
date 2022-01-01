#!/bin/sh
cd /root
/usr/local/etc/rc.d/nginx stop
acme.sh --register-account -m "%%SSLEMAIL%%" --server zerossl
acme.sh --force --issue -d %%DOMAIN%% --standalone
cd /root/.acme.sh/%%DOMAIN%%/
#mv * /usr/local/etc/ssl/
cp -f /root/.acme.sh/%%DOMAIN%%/* /usr/local/etc/ssl/
service nginx start
service synapse restart
