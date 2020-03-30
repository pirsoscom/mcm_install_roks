#!/bin/bash

check_prereq() {
  local TOOL=$1
  if ! command -v $TOOL >/dev/null 2>&1; then
    echo "$TOOL is required."
    PREREQ_CHECK_FAIL=1
  fi
}

check_prereqs() {
  PREREQ_CHECK_FAIL=0
  check_prereq "ibmcloud"
  check_prereq "curl"
  check_prereq "jq"
  if [ "$PREREQ_CHECK_FAIL" != "0" ]; then
    exit 1
  fi
}

get_bearer() {
    export IBMCLOUD_COLOR=false
    ibmcloud iam oauth-tokens | tr -s ' ' | awk '{ print $4 }'
}

list() {
    curl -s https://billing.cloud.ibm.com/v1/licensing/entitlements -H "Authorization: Bearer $(get_bearer)" | jq '.resources[] | [ .name ]'
}

get_key() {
    local NAME=$1
    if [ -z "$NAME" ]; then
        echo "Usage: $0 show-key <ENTITLEMENT NAME>" >&2
        exit 1
    fi
    curl -s https://billing.cloud.ibm.com/v1/licensing/entitlements -H "Authorization: Bearer $(get_bearer)" | jq -r ".resources[] | select(.name | test(\"$NAME\"; \"i\")) | .apikey"
}

docker_login() {
    local NAME=$1
    if [ -z "$NAME" ]; then
        echo "Usage: $0 docker-login <ENTITLEMENT NAME>" >&2
        exit 1
    fi
    ENTITLEMENT_KEY=$(get_key "$NAME")
    if [ -z "$ENTITLEMENT_KEY" ]; then
        echo "Error: Could not get entitlement key for $NAME" >&2
        exit 2
    fi
    ENTITLEMENT_USER=ekey
    ENTITLEMENT_REGISTRY=cp.icr.io
    echo "Log in to $ENTITLEMENT_REGISTRY using $ENTITLEMENT_USER"
    docker login "$ENTITLEMENT_REGISTRY" -u "$ENTITLEMENT_USER" -p "$ENTITLEMENT_KEY"
}

COMMAND=$1
shift

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 [list | show-key <ENTITLEMENT NAME> | docker-login <ENTITLEMENT NAME>]"
    exit 1
fi

check_prereqs

case "$COMMAND" in
    list)
        list
        shift
        ;;
    show-key)
        get_key "$1"
        shift
        ;;
    docker-login)
        docker_login "$1"
        shift
        ;;
    *)
        echo "Command $COMMAND not supported." >&2
        exit 1
esac
