#!/bin/bash
set -ex
#curl request to delete the index older thn 30 days
curl -X DELETE "http://es-client.log:9200/*-`date "+%Y%m%d" -d "30 days ago"`?pretty"

#curl command to send snapshot in s3_repository
curl -X PUT "http://es-client.log:9200/_snapshot/s3_repository/snapshot_`date +%Y-%m-%d-%H-%M`?wait_for_completion=true"
