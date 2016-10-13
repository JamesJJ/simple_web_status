#!/bin/bash

[ -z "${SLEEP}" ] && SLEEP='30'

[ ! -f /etc/curl_tests.txt ] && \
[ ! -z "${CURL_TESTS}" ] && \
cat <<EO_TESTS > "/etc/curl_tests.txt"
$CURL_TESTS
EO_TESTS

cat <<EO_PW_FILE1 > "/etc/nginx/conf.d/.htpasswd1"
$BASIC_AUTH1
EO_PW_FILE1

screen -d -m bash -c 'while true; do ./simple_web_check.sh; sleep "${SLEEP}";done'

exec nginx -g 'daemon off;'


