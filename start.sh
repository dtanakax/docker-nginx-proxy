#!/bin/bash

procfile=./Procfile

if [ "$TLSVERIFY" = "true" ]; then
    options="-tlsverify=true -tlscacert=/certs/ca.pem -tlscert=/certs/cert.pem -tlskey=/certs/key.pem"
    sed -i -e "s|<TLSVERIFY>|${options}|g" $procfile
fi

exec "$@"