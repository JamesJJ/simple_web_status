#!/bin/bash

[ -z "${SLEEP}" ] && SLEEP='30'
export SLEEP
[ ! -z "${CURL_ARGS}" ] && export CURL_ARGS
[ ! -z "${TITLE}" ] && export TITLE
[ ! -z "${RESULT_SORT}" ] && export RESULT_SORT


[ ! -f /etc/curl_tests.txt ] && \
[ ! -z "${CURL_TESTS}" ] && \
cat <<EO_TESTS | tee "/etc/curl_tests.txt"
$CURL_TESTS
EO_TESTS

cat <<EO_PW_FILE1 > "/etc/nginx/conf.d/.htpasswd1"
$BASIC_AUTH1
EO_PW_FILE1

cat <<EO_NGINX_EXTRA_CONF > "/etc/nginx/conf.d/nginx_extra_config.inc"
$NGINX_EXTRA_CONFIG
EO_NGINX_EXTRA_CONF

screen -d -m bash -c 'while true; do ./simple_web_check.sh; sleep "${SLEEP}";done'

exec nginx -g 'daemon off;'


