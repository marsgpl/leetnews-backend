#!/bin/zsh

SERVICE="mongo"

echo "docker recreate $SERVICE ..."
    ssh leetnews@marsgpl "docker-compose up -d --build --force-recreate $SERVICE" || exit 1
echo "OK"
