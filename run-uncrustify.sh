#!/bin/sh

# set uncrustify path or executable
# UNCRUSTIFY="/usr/bin/uncrustify"
UNCRUSTIFY="uncrustify"

while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        --check)
            CHECK=true
            ;;
        --apply)
            APPLY=true
            ;;
        *)
            # unknown option
            ;;
    esac
    shift # past argument or value
done

if [ "$CHECK" = true ] && [ "$APPLY" = true ] ; then
    echo "Please specify either --check or --apply"
    exit 1
fi

if [ "$CHECK" = true ] ; then
    OPTIONS="--check"
elif [ "$APPLY" = true ] ; then
    OPTIONS="--no-backup"
else
    echo "Please specify either --check or --apply"
    exit 1
fi


if ! command -v "$UNCRUSTIFY" > /dev/null ; then
    printf "Error: uncrustify executable not found.\n"
    printf "Set the correct path in $UNCRUSTIFY.\n"
    exit 1
fi

FILES="$(find {Classes,objcToxTests,objcToxDemo} -name '*.h' -or -name '*.m')"

$UNCRUSTIFY -c uncrustify.cfg  -l OC $OPTIONS $FILES
