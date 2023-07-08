#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# Adapt config files
#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create index via fake elasticsearch
# this should address the error:
# 'core.MultiSearchV2: error accessing reader: no index found'
# needs to be an existing index before parsedmarc will import correctly

# temp remove to test
# copy empty index json files to /tmp (might be redundant)
#cp -f "$TEMPLATEPATH/dmarc_aggregate.json.in" /tmp/dmarc_aggregate.json
#cp -f "$TEMPLATEPATH/dmarc_forensic.json.in" /tmp/dmarc_forensic.json

# testing something
echo "{}" > /tmp/dmarc_aggregate.json
echo "{}" > /tmp/dmarc_forensic.json

# set credentials for curl
echo "machine 127.0.0.1 login ${ZINCUSER} password ${ZINCPASS}" > /root/.netrc
echo "machine ${IP} login ${ZINCUSER} password ${ZINCPASS}" >> /root/.netrc

# create default empty index - parsedmarc will use dmarc_aggregate-YYYY-MM-DD
echo "Creating a default zincsearch aggregate index"
/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
  -X PUT --data-binary "@/tmp/dmarc_aggregate.json" "http://127.0.0.1:$ZINCPORT/es/dmarc_aggregate-$(date -I)" || true

echo "Creating a default zincsearch forensic index"
/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
  -X PUT --data-binary "@/tmp/dmarc_forensic.json" "http://127.0.0.1:$ZINCPORT/es/dmarc_forensic-$(date -I)" || true

# delete temporary files
echo "Deleting temp index json files"
rm -f /tmp/dmarc_aggregate.json
rm -f /tmp/dmarc_forensic.json
