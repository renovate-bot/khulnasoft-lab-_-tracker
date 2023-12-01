#!/bin/sh

#
# Entrypoint for the official tracker container images
#

# variables

TRACKER_TMP="/tmp/tracker"
TRACKER_OUT="${TRACKER_TMP}/out"
TRACKER_EXE=${TRACKER_EXE:="/tracker/tracker"}

LIBBPFGO_OSRELEASE_FILE=${LIBBPFGO_OSRELEASE_FILE:="/etc/os-release-host"}

CAPABILITIES_BYPASS=${CAPABILITIES_BYPASS:="0"}
CAPABILITIES_ADD=${CAPABILITIES_ADD:=""}
CAPABILITIES_DROP=${CAPABILITIES_DROP:=""}

# functions

run_tracker() {
    mkdir -p $TRACKER_OUT

    if [ $# -ne 0 ]; then
        # no default arguments, just given ones
        $TRACKER_EXE "$@"
    else
        # default arguments
        $TRACKER_EXE \
        --metrics \
        --cache cache-type=mem \
        --cache mem-cache-size=512 \
        --capabilities bypass=$CAPABILITIES_BYPASS \
        --capabilities add=$CAPABILITIES_ADD \
        --capabilities drop=$CAPABILITIES_DROP \
        --output=json \
        --output=option:parse-arguments \
        --output=option:relative-time \
        --events signatures,container_create,container_remove
    fi

    tracker_ret=$?
}

# startup

if [ ! -x $TRACKER_EXE ]; then
    echo "ERROR: cannot execute $TRACKER_EXE"
    exit 1
fi

if [ "$LIBBPFGO_OSRELEASE_FILE" == "" ]; then
    echo "ERROR:"
    echo "ERROR: You have to set LIBBPFGO_OSRELEASE_FILE env variable."
    echo "ERROR: It allows tracker to detect host environment features."
    echo "ERROR: "
    echo "ERROR: Run docker with :"
    echo "ERROR:     -v /etc/os-release:/etc/os-release-host:ro"
    echo "ERROR: "
    echo "ERROR: Then you may set LIBBPFGO_OSRELEASE_FILE:"
    echo "ERROR:     -e LIBBPFGO_OSRELEASE_FILE=/etc/os-release-host"
    echo "ERROR:"

    exit 1
fi

if [ ! -f "$LIBBPFGO_OSRELEASE_FILE" ]; then
    echo "ERROR:"
    echo "ERROR: You provided a LIBBPFGO_OSRELEASE_FILE variable but"
    echo "ERROR: missed providing the bind mount for it."
    echo "ERROR:"
    echo "ERROR: Try docker with: -v /etc/os-release:/etc/os-release-host:ro"
    echo "ERROR:"

    exit 1
fi

#
# main
#

run_tracker $@

if [ $tracker_ret -eq 2 ]; then
    echo "INFO:"
    echo "INFO: It seems that your environment isn't supported by Tracker."
    echo "INFO: If you think this is an error, please open an issue at:"
    echo "INFO:"
    echo "INFO: https://github.com/khulnasoft-lab/tracker/"
    echo "INFO:"
fi

exit $tracker_ret
