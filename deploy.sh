#!/bin/zsh

CMD="$1" # default: api

if [[ "$CMD" == "all" ]]; then
    ./deploy/mongo.sh || exit 1
    ./deploy/crawler.sh || exit 1
    ./deploy/api.sh || exit 1
elif [[ "$CMD" == "mongo" ]]; then
    ./deploy/mongo.sh || exit 1
elif [[ "$CMD" == "crawler" ]]; then
    ./deploy/crawler.sh || exit 1
else
    ./deploy/api.sh || exit 1
fi
