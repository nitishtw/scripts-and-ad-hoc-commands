#!/bin/bash
mkdir -p /tmp/destination1 /tmp/destination2
find . -type f -print0 | xargs -0 mv -t /tmp/destination1
find . -type d -print0 | xargs -0 mv -t /tmp/destination2
