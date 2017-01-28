#!/bin/bash

# delete existing user account for nginx
/usr/bin/htpasswd -D /config/nginx/security/auth "$1"

status=$?

if [[ $status -eq 0 ]]; then
  echo "User account $1 deleted."
else
  echo "Failed to delete user account $1, does it exist?"
fi

# show contents of password file with obfuscated password
/usr/bin/cat /config/nginx/security/auth
