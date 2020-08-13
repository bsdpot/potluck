#!/bin/sh
cd /root
/usr/local/etc/rc.d/nginx stop
acme.sh --force --issue -d $SERVERNAME --standalone
cd /root/.acme.sh/$SERVERNAME/
mv * /usr/local/etc/ssl/
/usr/local/etc/rc.d/nginx start
/usr/local/etc/rc.d/synapse restart
