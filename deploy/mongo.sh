#!/bin/zsh

echo "docker recreate ..."
    ssh leetnews@marsgpl "docker-compose up -d --build --force-recreate mongo" || exit 1
echo "OK"
