#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
usage() { echo "Usage: $0 [-e GLOB] [-s] [-c] [-u] FILES ..." 1>&2; exit 1; }

EXCLUDE=()
ALLOW_SUPPORTED=0
UPDATE=0
FINDINGS=0

while getopts ":e:iscou" o; do
    case "${o}" in
        e)
            EXCLUDE+=("${OPTARG}")
            ;;
        s)
            ALLOW_SUPPORTED=1
            ;;
        u)
            UPDATE=1
            ;;
        *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

if [ $UPDATE == 1 ]
then
    echo 'web-puc version 0.0.2 by William Entriken'
    echo
    rm packages/*
    for SCRIPT in $(ls $BASEDIR/package-spiders/*.sh)
    do
        echo -e " \033[1;33m\033[40m  UPDATING $SCRIPT \033[0m"
        . "$SCRIPT"
    done
    exit 0
elif [ "$#" -eq 0 ]
then
    usage
    exit 0
fi

EXCLUDEOPTS=()
for i in "${EXCLUDE[@]}"
do
    EXCLUDEOPTS+=("-path")
    EXCLUDEOPTS+=("$i")
    EXCLUDEOPTS+=("-or")
done
IFS=$'\n'
FILES=$(find "$@" -type f -and \! \( "${EXCLUDEOPTS[@]}" -false \))

echo '{'
echo '  "statVersion": "0.3.1",'
echo '  "process": {'
echo '    "name": "web-puc",'
echo '    "version": "0.0.2"'
echo '  },'
echo '  "findings": ['

for FILE in $FILES
do
    for GOODFILE in $(ls $BASEDIR/packages/*.good)
    do
        BADFILE="$BASEDIR/packages/"$(basename $GOODFILE .good)".bad"
        BADMATCH=$(grep -o -nh -F -f $BADFILE $FILE)
        for MATCH in $BADMATCH
        do
          FINDINGS=$((FINDINGS + 1))
          if [ $FINDINGS -gt 1 ]
          then
            echo "    ,"
          fi
          LINE=$(echo "$MATCH" | cut -d: -f 1)
          TEXT=$(echo "$MATCH" | cut -d: -f 2-)

          echo '    {'
          echo '      "failure": true,'
          echo '      "rule": "Old version",'
          echo "      \"description\": \"$TEXT\","
          echo '      "location": {'
          echo "        \"path\":\"$FILE\","
          echo "        \"beginLine\": $LINE,"
          echo "        \"endLine\": $LINE"
          echo '      },'
          echo "      \"recommendation\": \""$(cat $GOODFILE)"\""
          echo '    }'
        done
    done
done

echo '  ]'
echo '}'
