#!/bin/zsh

CMD="$1" # default: api

if [[ "$CMD" == "mongo" ]]; then
    ./deploy/mongo.sh || exit 1
elif [[ "$CMD" == "crawler" ]]; then
    ./deploy/crawler.sh || exit 1
elif [[ "$CMD" == "api" ]]; then
    ./deploy/api.sh || exit 1
fi
