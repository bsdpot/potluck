#!/bin/sh

service consul reload
service nginx reload consulmetricsproxy
exit 0
