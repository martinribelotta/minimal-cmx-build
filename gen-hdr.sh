#!/bin/sh

set -e
if [ "x$DEBUG" = "xy" ]; then
    set -x
fi

if [ -z $1 ]; then
    echo "$0 <.config>"
    exit 1
fi

cat $1 | grep -vE '^#|^$' | while read line
do
    SYM=$(echo "$line" | cut -d '=' -f 1 | tr '-' '_')
    VAL=$(echo "$line" | cut -d '=' -f 2)
    if [ "x$VAL" = "xy" ]; then
        VAL=1
    fi
    printf "#define %-60s%b\n" $SYM $VAL
done
