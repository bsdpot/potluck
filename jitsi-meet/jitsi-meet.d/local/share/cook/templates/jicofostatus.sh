#!/usr/local/bin/bash

curl -s "http://localhost:8080/debug?full=true" | jq .
