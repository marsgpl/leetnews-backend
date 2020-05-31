#!/bin/zsh

CMD="$1"
SKIP_BUILD="$2" # any value to skip build

if [[ "$CMD" == "mongo" ]]; then
    ./deploy/mongo-restart.sh || exit 1
elif [[ "$CMD" == "util" ]]; then
    if [[ -z "$SKIP_BUILD" ]]; then
        ./deploy/build.sh util || exit 1
    fi
    ./deploy/restart.sh util || exit 1
elif [[ "$CMD" == "crawler" ]]; then
    if [[ -z "$SKIP_BUILD" ]]; then
        ./deploy/build.sh crawler || exit 1
    fi
    ./deploy/restart.sh crawler || exit 1
elif [[ "$CMD" == "api" ]]; then
    if [[ -z "$SKIP_BUILD" ]]; then
        ./deploy/build.sh api || exit 1
    fi
    ./deploy/restart.sh api || exit 1
else
    echo "unknown command: $CMD" 1>&2
    exit 1
fi
