# Leetnews

News app

<https://leetnews.net>

## Prepare for deploy

    ./upload.sh

## Deploy

    ./deploy.sh

## Links

    <https://dart.dev/tutorials/server/httpserver>
    <https://pub.dev/packages/http_server>
    <https://pub.dev/packages/mongo_dart>

## Local start

    docker-compose up --build --force-recreate api
    docker-compose up api

## Local debug

    docker exec -it leetnews_api_1 bash
