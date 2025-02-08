#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

echo "Importing job files from /root/nomadjobs"
cd /root/nomadjobs/
# count .nomad files in /root/nomadjobs
# shellcheck disable=SC2012,SC2035
JOBSCOUNT=$(ls *.nomad |wc -l)
# for each .nomad job file run nomad plan
if [ "${JOBSCOUNT}" -gt "0" ];then
    # get a file list of .nomad files
    JOBSLIST=$(find . -type f -name "*.nomad")
    # nomad job plan /root/jobfiles/jobname.nomad
    # shellcheck disable=SC2116
    for job in $(echo "${JOBSLIST}"); do
        /usr/local/bin/nomad job run -address="http://${IP}:4646" -detach "$job";
    done
fi