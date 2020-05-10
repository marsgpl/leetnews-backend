# Leetnews

[API docs](https://github.com/marsgpl/leetnews-backend/wiki/API-docs)

## Prepare for deploy

    ./upload.sh

## Deploy

    ./deploy.sh

## Links

    <https://dart.dev/tutorials/server/httpserver>
    <https://pub.dev/packages/http_server>
    <https://pub.dev/packages/mongo_dart>

## Local start

    docker-compose up -d mongo
    docker-compose up --build --force-recreate api
    docker-compose up api
    docker-compose up --build --force-recreate crawler
    docker-compose up crawler

## Local debug

    docker-compose logs -f api
    docker-compose logs -f crawler
    docker-compose logs -f mongo

    docker exec -it leetnews_api_1 bash
    docker exec -it leetnews_mongo_1 mongo -u root -pnl7QkdoQiqIEnSse8IMgBUfEp7gOThr2
        show databases;
        use news;
        show collections;
        db.posts.count({});
        db.posts.find({}).limit(1).pretty();
        db.posts.remove({});
        db.posts.drop();

## Indexes

    use news;
    db.posts.ensureIndex({ "pubDate": 1 });
