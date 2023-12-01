#!/bin/bash

#
# This test attempts to compile tracker using upstream libbpfgo.
# It's run by github workflows inside action runners, just as
# it can be run locally. In both cases it must be triggered by
# 'make test-upstream-libbpfgo'.
#

info() {
    echo -n "INFO: "
    echo "$@"
}

error_exit() {
    echo -n "ERROR: "
    echo "$@"
    exit 1
}

git_setup() {
    git add go.mod go.sum
    if ! go get github.com/khulnasoft-lab/libbpfgo@main;
    then
        git restore --staged go.mod go.sum
        error_exit "could not go get libbpfgo@main"
    fi
}

git_restore() {
    git checkout go.mod go.sum
    git restore --staged go.mod go.sum
}

BASE_DIR="$(dirname "$(realpath "${0}")")"
TRACKER_DIR="$(realpath "${BASE_DIR}"/..)"
GO_ENV_EBPF=( "$@" )
export "${GO_ENV_EBPF[@]}"

git_setup
trap git_restore ERR

set -e
STATIC=1 make -C "${TRACKER_DIR}"
set +e

git_restore

info "SUCCESS"

exit 0
