#!/bin/bash

TRACKER_STARTUP_TIMEOUT=60
TRACKER_SHUTDOWN_TIMEOUT=60
TRACKER_RUN_TIMEOUT=5

TRACKER_TMP_DIR=/tmp/bpf_attach

info_exit() {
    echo -n "INFO: "
    echo "$@"
    exit 0
}

info() {
    echo -n "INFO: "
    echo "$@"
}

# run tracker with a single event (to trigger the other instance)

rm -f $TRACKER_TMP_DIR/tracker.pid

./dist/tracker \
    --install-path $TRACKER_TMP_DIR \
    --output none \
    --events security_file_open &

pid=$?

# wait tracker to be started + 5 seconds

times=0
timedout=0

while true; do
    times=$((times + 1))
    sleep 1

    if [[ -f $TRACKER_TMP_DIR/tracker.pid ]]; then
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
kill -SIGINT "$pid"

# wait tracker to shutdown (might take sometime, detaching is slow >= v6.x)
sleep $TRACKER_SHUTDOWN_TIMEOUT

# make sure tracker is exited with SIGKILL
kill -SIGKILL "$pid" >/dev/null 2>&1

exit 0
