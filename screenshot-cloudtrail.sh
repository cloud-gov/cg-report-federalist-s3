#!/bin/bash

set -eux
locale -a
export LC_CTYPE=C.UTF-8
export TERM="xterm-256color"
pip3 install asciinema
asciinema rec recording/federalist-report.json -c report-federalist/query-cloudtrail.sh
sleep 1
asciinema play recording/federalist-report.json
