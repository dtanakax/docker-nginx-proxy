#!/bin/bash

procfile=./Procfile

if [ "$DOCKER_TLS_VERIFY" = "true" ]; then
    options="-tlsverify=true -tlscacert=/certs/ca.pem -tlscert=/certs/cert.pem -tlskey=/certs/key.pem"
    sed -i -e "s|<DOCKER_TLS_VERIFY>|${options}|g" $procfile
fi

exec "$@"