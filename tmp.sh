#!/bin/bash

list=(
adminer
beast-of-argh
consul
consul-tls
dmarc-report
grafana
haproxy
haproxy-consul
haproxy-minio
haproxy-sql
hugo-nginx
hugo-nginx-alt
influxdb
jenkins
jitsi-meet
loki
mailhub-potluck
mariadb
mariadb-galera
mastodon-s3
matrix-synapse
nextcloud-spreed-signalling
nginx-consul
nginx-rsync-ssh
nomad-server
nomad-server-tls
openldap
opensearch
pixelfed
postgresql-patroni
postgres-single
prometheus
rbldnsd
redis-single
saltstack
traefik-consul
traumadrill
vault
zincsearch
)


for p in ${list[@]}; do
    echo $p
    sed "1i$(grep version ${p}/${p}.ini | cut -d '"' -f 2)" ${p}/CHANGELOG.md -i
    sed -E -e $'2i\n' ${p}/CHANGELOG.md -i
    sed '3i* Enable milliseconds in syslog-ng for all log timestamps' ${p}/CHANGELOG.md -i
    sed -E -e $'4i\n' ${p}/CHANGELOG.md -i
    sed '5i---' ${p}/CHANGELOG.md -i
    sed -E -e $'6i\n' ${p}/CHANGELOG.md -i
done
