#!/bin/bash

[ -z "${SLEEP}" ] && SLEEP='30'

screen -d -m bash -c 'while true; do ./simple_web_check.sh; sleep "${SLEEP}";done'

exec nginx -g 'daemon off;'


