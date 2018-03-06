#!/bin/bash
set -eu

echo "Querying CloudTrail @ $(date) for bucket ${BUCKET}"
echo
aws cloudtrail lookup-events --region us-gov-west-1 --lookup-attributes AttributeKey=ResourceName,AttributeValue=${BUCKET} \
  | jq '.Events[] | [{EventId: .EventId, EventName: .EventName, EventTime: .EventTime, Username: .Username}]'

sleep 5