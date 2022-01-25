#!/bin/bash

if [ "${1}" = "-D" ]; then
    # start supervisord and services
    exec /usr/bin/supervisord -n -c /etc/supervisord.conf
else
    exec "$@"
fi