#!/bin/bash
set -eu
echo
echo "Date:         $(date)"
echo "S3 bucket:    ${BUCKET}"
echo
set -x
aws cloudtrail lookup-events --region us-gov-west-1 --lookup-attributes AttributeKey=ResourceName,AttributeValue=${BUCKET} \
  | jq '.Events[] | [{EventId: .EventId, EventName: .EventName, EventTime: .EventTime, Username: .Username}]'

{ set +x; } 2> /dev/null # silently disable xtrace
echo
sleep 5