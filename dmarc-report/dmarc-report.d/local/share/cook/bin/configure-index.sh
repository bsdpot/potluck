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
SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create index via fake elasticsearch
# this should address the error:
# 'core.MultiSearchV2: error accessing reader: no index found'
# Any index will do, just needs to be an existing index before parsedmarc will import correctly

# copy empty index json files to /tmp (might be redundant)
cp -f "$TEMPLATEPATH/dmarc_aggregate.json.in" /tmp/dmarc_aggregate.json
cp -f "$TEMPLATEPATH/dmarc_forensic.json.in" /tmp/dmarc_forensic.json

# set credentials
echo "machine 127.0.0.1 login ${ZINCUSER} password ${ZINCPASS}" > /root/.netrc

# check zincsearch responding
# localhost:9200 is the fake elasticsearch reverse proxy to zincsearch
zinclivecheck=$(/usr/local/bin/curl -s "http://127.0.0.1:9200/" | jq -r .name )

# if zincsearch is up, use curl to create a sample index using local json file
if [ "$zinclivecheck" = "zinc" ]; then
	echo "Creating a default zincsearch aggregate index"
	/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
	  -X PUT --data-binary @/tmp/dmarc_aggregate.json http://127.0.0.1:9200/dmarc_aggregate | jq -r .acknowledged

	echo "Creating a default zincsearch forensic index"
	/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
	  -X PUT --data-binary @/tmp/dmarc_forensic.json http://127.0.0.1:9200/dmarc_forensic | jq -r .acknowledged

	# delete temporary files
	echo "Deleting temp index json files"
	rm -r /tmp/dmarc_aggregate.json /tmp/dmarc_forensic.json
else
	echo "Cannot create index, zincsearch is not live"
	exit 1
fi
