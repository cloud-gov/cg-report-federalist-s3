#!/bin/bash
set -eux
date
aws cloudtrail lookup-events --region us-gov-west-1 --lookup-attributes AttributeKey=ResourceName,AttributeValue=${BUCKET} \
  | jq '.Events[] | [{id: .EventId, type: .EventName, timestamp: .EventTime, user: .Username}]'

{ set +x; } 2> /dev/null # silently disable xtrace
sleep 5