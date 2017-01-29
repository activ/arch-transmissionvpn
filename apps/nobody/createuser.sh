#!/bin/bash

# create new user account for nginx
if [[ ! -f "/config/nginx/security/auth" ]]; then
  /usr/bin/htpasswd -c /config/nginx/security/auth "$1"
else
  /usr/bin/htpasswd /config/nginx/security/auth "$1"
fi

# show contents of password file with obfuscated password
/usr/bin/cat /config/nginx/security/auth
