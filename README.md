# Leetnews

News app

<https://leetnews.net>

## Start

    docker-compose up --build --force-recreate api
    docker-compose up api

## Deploy

    ./upload.sh
    ./deploy.sh

## Links

    <https://dart.dev/tutorials/server/httpserver>
    <https://pub.dev/packages/http_server>
    <https://pub.dev/packages/mongo_dart>

## Debug

    docker exec -it leetnews_api_1 bash
