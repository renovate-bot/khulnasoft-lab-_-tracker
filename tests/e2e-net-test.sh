#!/bin/bash

#
# This test is executed by github workflows inside the action runners
#

TRACKER_STARTUP_TIMEOUT=60
TRACKER_SHUTDOWN_TIMEOUT=60
TRACKER_RUN_TIMEOUT=60
SCRIPT_TMP_DIR=/tmp
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

if [[ $UID -ne 0 ]]; then
    error_exit "need root privileges"
fi

if [[ ! -d ./signatures ]]; then
    error_exit "need to be in tracker root directory"
fi

KERNEL=$(uname -r)
KERNEL_MAJ=$(echo $KERNEL | cut -d'.' -f1)

if [[ $KERNEL_MAJ -lt 5 && "$KERNEL" != *"el8"* ]]; then
    info_exit "skip test in kernels < 5.0 (and not RHEL)"
fi

# run CO-RE IPv4 test only by default
TESTS=${NETTESTS:=IPv4}

# startup needs
rm -rf $TRACKER_TMP_DIR/* || error_exit "could not delete $TRACKER_TMP_DIR"
git config --global --add safe.directory "*"

info
info "= ENVIRONMENT ================================================="
info
info "KERNEL: $(uname -r)"
info "CLANG: $(clang --version)"
info "GO: $(go version)"
info
info "= SETUP NETWORK TESTING ENV  =================================="
info
timeout --preserve-status 20 ./tests/e2e-net-signatures/scripts/setup.sh
ret=$?
if [[ $ret -ne 0 ]]; then
    error_exit "could not setup network namespaces: error $ret"
fi
info
info "= COMPILING TRACKER ============================================"
info
# make clean # if you want to be extra cautious
set -e
make -j$(nproc) all
make e2e-net-signatures
set +e
if [[ ! -x ./dist/tracker-ebpf || ! -x ./dist/tracker-rules ]]; then
    error_exit "could not find tracker executables"
fi

# if any test has failed
anyerror=""

# run tests
for TEST in $TESTS; do

    info
    info "= TEST: $TEST =============================================="
    info

    rm -f $SCRIPT_TMP_DIR/build-$$
    rm -f $SCRIPT_TMP_DIR/ebpf-$$

    events=$(./dist/tracker-rules --allcaps --rules-dir ./dist/e2e-net-signatures/ --rules $TEST --list-events)

    ./dist/tracker-ebpf \
        --install-path $TRACKER_TMP_DIR \
        --cache cache-type=mem \
        --cache mem-cache-size=512 \
        --output format:json \
        --output option:parse-arguments \
        --scope comm=ping,nc,nslookup,isc-net-0000,isc-worker0000,curl \
        --events $events \
        2>$SCRIPT_TMP_DIR/ebpf-$$ |
        ./dist/tracker-rules \
            --rules-dir ./dist/e2e-net-signatures/ \
            --input-tracker=file:stdin \
            --input-tracker format:json \
            --rules $TEST \
            --allcaps 2>&1 |
        tee $SCRIPT_TMP_DIR/build-$$ 2>&1 &

    # wait tracker-ebpf to be started (30 sec most)
    times=0
    timedout=0
    while true; do
        times=$(($times + 1))
        sleep 1
        if [[ -f $TRACKER_TMP_DIR/out/tracker.pid ]]; then
            info
            info "UP AND RUNNING"
            info
            break
        fi

        if [[ $times -gt $TRACKER_STARTUP_TIMEOUT ]]; then
            timedout=1
            break
        fi
    done

    # tracker-ebpf could not start for some reason, check stderr
    if [[ $timedout -eq 1 ]]; then
        info
        info "$TEST: FAILED. ERRORS:"
        info
        cat $SCRIPT_TMP_DIR/ebpf-$$

        anyerror="${anyerror}$TEST,"
        continue
    fi

    # give some time for tracker to settle
    sleep 3

    # run test scripts
    timeout --preserve-status $TRACKER_RUN_TIMEOUT \
        ./tests/e2e-net-signatures/scripts/${TEST,,}.sh

    # so event can be processed and detected
    sleep 3

    ## cleanup at EXIT

    found=0
    cat $SCRIPT_TMP_DIR/build-$$ | grep "Signature ID: $TEST" -B2 | head -3 | grep -q "\*\*\* Detection" && found=1
    info
    if [[ $found -eq 1 ]]; then
        info "$TEST: SUCCESS"
    else
        anyerror="${anyerror}$TEST,"
        info "$TEST: FAILED, stderr from tracker-ebpf:"
        cat $SCRIPT_TMP_DIR/ebpf-$$
        info
    fi
    info

    rm -f $SCRIPT_TMP_DIR/build-$$
    rm -f $SCRIPT_TMP_DIR/ebpf-$$

    # make sure we exit both to start them again

    pid_rules=$(pidof tracker-rules)
    pid_ebpf=$(pidof tracker-ebpf)

    kill -2 $pid_rules
    kill -2 $pid_ebpf

    sleep $TRACKER_SHUTDOWN_TIMEOUT

    # make sure tracker is exited with SIGKILL
    kill -9 $pid_rules >/dev/null 2>&1
    kill -9 $pid_ebpf >/dev/null 2>&1

    # give a little break for OS noise to reduce
    sleep 3

    # cleanup leftovers
    rm -rf $TRACKER_TMP_DIR
done

info
if [[ $anyerror != "" ]]; then
    info "ALL TESTS: FAILED: ${anyerror::-1}"
    exit 1
fi

info "ALL TESTS: SUCCESS"

exit 0
