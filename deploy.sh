#!/bin/zsh

CMD="$1"

if [[ "$CMD" == "all" ]]; then
    ./deploy/api.sh || exit 1
else
    ./deploy/api.sh || exit 1
fi
