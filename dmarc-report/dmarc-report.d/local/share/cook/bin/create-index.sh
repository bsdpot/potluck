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

cp -f "$TEMPLATEPATH/index.json.in" /tmp/dmarc_aggregate.json
cp -f "$TEMPLATEPATH/index.json.in" /tmp/dmarc_forensic.json

# set credentials for curl, this uses default opensearch credentials
echo "machine 127.0.0.1 login admin password admin" > /root/.netrc
echo "machine ${IP} login admin password admin" >> /root/.netrc

# create default empty index - parsedmarc will use dmarc_aggregate-YYYY-MM-DD
echo "Creating a default opensearch aggregate index"
/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
  -X PUT --data-binary "@/tmp/dmarc_aggregate.json" "http://127.0.0.1:9200/dmarc_aggregate-$(date -I)" || true

echo "Creating a default opensearch forensic index"
/usr/local/bin/curl --silent --retry 5 --retry-delay 5 --retry-all-errors --netrc \
  -X PUT --data-binary "@/tmp/dmarc_forensic.json" "http://127.0.0.1:9200/dmarc_forensic-$(date -I)" || true

# delete temporary files
echo "Deleting temp index json files"
rm -f /tmp/dmarc_aggregate.json
rm -f /tmp/dmarc_forensic.json

# setup /root/create-alias.sh
mkdir -p /root/bin
cp -f "$TEMPLATEPATH/create-alias.sh.in" /root/bin/create-alias.sh
chmod +x /root/bin/create-alias.sh

# create the alias
createalias=$(/root/bin/create-alias.sh)
echo "$createalias"
