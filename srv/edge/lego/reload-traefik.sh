#!/bin/sh
# Hook script to touch certs.yml after certificate renewal
# This triggers Traefik to reload the certificate configuration

touch /config/certs.yml

