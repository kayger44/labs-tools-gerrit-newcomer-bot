#!/usr/bin/env bash
#
# Management script for gerrit-newcomer-bot kubernetes processes
#
# This file should be placed in the tool directory:
# `/data/project/gerrit-newcomer-bot/bin`

set -e

DEPLOYMENT=gerrit-newcomer-bot.bot
POD_NAME=gerrit-newcomer-bot.bot

TOOL_DIR=$(cd $(dirname $0)/.. && pwd -P)
VENV=${TOOL_DIR}/www/python/venv/
if [[ -f ${VENV}/bin/activate ]]; then
    # Enable virtualenv
    echo "Setting up virtualenv..."
    source ${VENV}/bin/activate
else
    echo "Virtualenv not found!"
    echo "Expected it to be in ${VENV}"
    echo "I'm going to stop and let you fix that."
    exit 1
fi
# Uncomment to debug packages installed in the venv
# which python3
# pip3 list
# exit

_get_pod() {
    kubectl get pods \
        --output=jsonpath={.items..metadata.name} \
        --selector=name=${POD_NAME}
}

case "$1" in
    start)
        echo "Starting gerrit-newcomer-bot k8s deployment..."
        kubectl create -f ${TOOL_DIR}/etc/gerrit-newcomer-bot.yaml
        ;;
    run)
        echo "Running gerrit-newcomer-bot..."
        cd ${TOOL_DIR}/www/python/src/
        exec ${VENV}/bin/python3 watch_newcomers.py
        ;;
    stop)
        echo "Stopping gerrit-newcomer-bot k8s deployment..."
        kubectl delete deployment ${DEPLOYMENT}
        ;;
    restart)
        echo "Restarting gerrit-newcomer-bot k8s deployment..."
        $0 stop &&
        $0 start
        ;;
    status)
        echo "Active pods:"
        kubectl get pods -l name=${POD_NAME}
        ;;
    tail)
        exec kubectl logs -f $(_get_pod)
        ;;
    update)
        echo "Updating git clone..."
        cd ${TOOL_DIR}/www/python/src/
        git fetch &&
        git --no-pager log --stat HEAD..@{upstream} &&
        git rebase @{upstream}
        ;;
    attach)
        echo "Attaching to pod..."
        exec kubectl exec -i -t $(_get_pod) /bin/bash
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|tail|update|attach}"
        exit 1
        ;;
esac

exit 0
# vim:ft=sh:sw=4:ts=4:sts=4:et:
