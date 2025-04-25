#!/bin/zsh

setopt err_exit
setopt no_unset
setopt pipe_fail

export SCRIPT_DIR="${0:A:h}"
export CONFIG_DIR="${SCRIPT_DIR}/cfg"
export LOCAL_ZINC_DATA_PATH="${SCRIPT_DIR}/../data/openobserve"
export OPENOBSERVE_CONTAINER_NAME="local-openobserve"
export OPENOBSERVE_IMAGE_NAME="public.ecr.aws/zinclabs/openobserve"
export OPENOBSERVE_IMAGE_TAG="v0.14.5"

function die() {
    local msg="$1"
    printf "%s\n" "${msg}" >&2
    exit 222
}

function stop_openobserve() {
    printf "stopping openobserve container [name=%s]\n" "${OPENOBSERVE_CONTAINER_NAME}"
    docker kill "${OPENOBSERVE_CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${OPENOBSERVE_CONTAINER_NAME}" >/dev/null 2>&1 || true
    printf "stopped openobserve container [name=%s]\n" "${OPENOBSERVE_CONTAINER_NAME}"
}

function start_openobserve() {
    # create data directory for storing zinc data, if it doesn't exist
    mkdir -p "${LOCAL_ZINC_DATA_PATH}"
    printf "starting openobserve container\n"
    docker create -i -t \
        --name ${OPENOBSERVE_CONTAINER_NAME} \
        --mount type=bind,src=${LOCAL_ZINC_DATA_PATH},dst=/data \
        --mount type=bind,src=/etc/localtime,dst=/etc/localtime,ro \
        --tmpfs=/tmp:rw,noexec,nosuid,size=128m \
        -p 5080:5080 \
        --network observe \
        -e ZO_ROOT_USER_EMAIL="root@example.com" \
        -e ZO_ROOT_USER_PASSWORD="Complexpass#123" \
        ${OPENOBSERVE_IMAGE_NAME}:${OPENOBSERVE_IMAGE_TAG}
    printf "started openobserve container [name=%s]\n" "${OPENOBSERVE_CONTAINER_NAME}"
    # attach the container's in/out file descriptors
    docker start -ia ${OPENOBSERVE_CONTAINER_NAME}
}

function cleanup() {
    # do any necessary cleanup here to make sure program doesn't
    # leave something running after exit.
    printf "cleanup called\n"
    stop_openobserve
}

# call cleanup function on exit to remove anything
# we may have created
trap 'cleanup' EXIT
start_openobserve || die "uhoh, couldn't start openobserve"
