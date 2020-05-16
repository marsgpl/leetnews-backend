# Leetnews

[API docs](https://github.com/marsgpl/leetnews-backend/wiki/API-docs)

## Prepare for deploy

    ./upload.sh

## Deploy

    ./deploy.sh mongo
    ./deploy.sh crawler
    ./deploy.sh api
    ./deploy.sh util

## Links

    <https://dart.dev/tutorials/server/httpserver>
    <https://pub.dev/packages/http_server>
    <https://pub.dev/packages/mongo_dart>

## Local

    docker network create leetnews

    docker-compose up -d mongo
    docker-compose up util
    docker-compose up crawler
    docker-compose up api

    docker-compose up -d --build --force-recreate mongo
    docker-compose up --build --force-recreate util
    docker-compose up --build --force-recreate crawler
    docker-compose up --build --force-recreate api

    docker-compose logs -f mongo

## DB

    docker exec -it leetnews_mongo_1 mongo 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin&appName=cli'

    db.disableFreeMonitoring();
    db.getProfilingLevel();
    show databases;
    show collections;
    use news;
    db.categories.count();
    db.posts.count();
    db.posts.find({}).sort({ pubDate: -1 }).limit(1).pretty();
    db.posts.remove({});
    db.posts.drop();
    db.posts.count({ title: /^Заразившаяся коронавирусом Татьяна Навка показала/ });
    db.posts.find({ title: /^Заразившаяся коронавирусом Татьяна Навка показала/ }).pretty();

    db.posts.find(
        {$text: {$search: "Заразившаяся коронавирусом Татьяна Навка показала фото"}},
        {score: {$meta: "textScore"}}
    ).sort({ score: { $meta: "textScore" } });

    db.posts.aggregate(
        {$match: {origId: {$ne: null}}},
        {$group: {_id: "$origId", count: {$sum: 1}}},
        {$match: {count: {$gt: 1}}},
        {$sort: {count: -1}},
        {$project: {_id: 0, origId: "$_id", count: "$count"}});

## DB indexes

    use news;
    db.posts.ensureIndex({ "pubDate": 1 });
    db.posts.ensureIndex({ "category": 1 });
    db.posts.ensureIndex({ "origId": 1 }, { "unique": true });
    db.posts.ensureIndex({ "title": "text", "text": "text" });
    db.posts.getIndexes();

## Move DB posts to local

    ssh leetnews@marsgpl 'docker exec -t leetnews_mongo_1 mongoexport --uri="mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin" --collection=posts --out=/data/db/posts.json'

    scp leetnews@marsgpl:/home/leetnews/mongo-data/posts.json ./mongo-data/

    ssh root@marsgpl 'rm /home/leetnews/mongo-data/posts.json'

    docker exec -t leetnews_mongo_1 mongoimport --uri="mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin" --collection=posts --file=/data/db/posts.json --drop

    rm ./mongo-data/posts.json

    add indexes
