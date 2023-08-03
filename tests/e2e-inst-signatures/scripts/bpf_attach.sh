#!/bin/bash

TRACKER_STARTUP_TIMEOUT=60
TRACKER_SHUTDOWN_TIMEOUT=60
TRACKER_RUN_TIMEOUT=5

TRACKER_TMP_DIR=/tmp/tracker

info_exit() {
    echo -n "INFO: "
    echo $@
    exit 0
}

info() {
    echo -n "INFO: "
    echo $@
}

error_exit() {
    echo -n "ERROR: "
    echo $@
    exit 1
}

# run tracker with a single event (to trigger the other instance)

coproc ./dist/tracker \
    --install-path $TRACKER_TMP_DIR \
    --events security_file_open &

pid=$COPROC_PID

# wait tracker to be started + 5 seconds

times=0
timedout=0

while true; do
    times=$(($times + 1))
    sleep 1

    if [[ -f $TRACKER_TMP_DIR/out/tracker.pid ]]; then
        info "bpf_attach test tracker instance started"
        break
    fi

    if [[ $times -gt $TRACKER_STARTUP_TIMEOUT ]]; then
        timedout=1
        break
    fi
done

if [[ $timedout -eq 1 ]]; then
    info_exit "could not start the bpf_attach test tracker instance"
fi

sleep $TRACKER_RUN_TIMEOUT # stay alive for sometime (proforma)

# try a clean exit
kill -2 $pid

# wait tracker to shutdown (might take sometime, detaching is slow >= v6.x)
sleep $TRACKER_SHUTDOWN_TIMEOUT

# make sure tracker is exited with SIGKILL
kill -9 $pid_tracker >/dev/null 2>&1

exit 0
