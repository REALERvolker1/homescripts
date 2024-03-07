#!/usr/bin/env dash

docker container ls --no-trunc --format json 2>/dev/null | grep -c '"ID":' || true
