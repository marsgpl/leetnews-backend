# Leetnews

[API docs](https://github.com/marsgpl/leetnews-backend/wiki/API-docs)

## Prepare for deploy

    ./upload.sh

## Deploy

    ./deploy.sh mongo
    ./deploy.sh crawler
    ./deploy.sh api

## Links

    <https://dart.dev/tutorials/server/httpserver>
    <https://pub.dev/packages/http_server>
    <https://pub.dev/packages/mongo_dart>

## Local start

    docker-compose up -d mongo
    docker-compose up crawler
    docker-compose up api

    docker-compose up --build --force-recreate mongo
    docker-compose up --build --force-recreate crawler
    docker-compose up --build --force-recreate api

## Local debug

    docker-compose logs -f mongo
    docker-compose logs -f crawler
    docker-compose logs -f api

    docker exec -it leetnews_api_1 bash
    docker exec -it leetnews_mongo_1 mongo -u root -pnl7QkdoQiqIEnSse8IMgBUfEp7gOThr2
        show databases;
        use news;
        show collections;
        db.posts.count();
        db.posts.find({}).limit(1).pretty();
        db.posts.remove({});
        db.posts.drop();
        db.posts.find({ "title": /^Заразившаяся коронавирусом Татьяна Навка показала фото из больницы/ }).pretty();
        db.categories.count();
        db.getProfilingLevel();

        db.posts.aggregate(
            {"$match": {"origId": {"$ne": null}}},
            {"$group": {"_id": "$origId", "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
            {"$sort": {"count": -1}},
            {"$project": {"origId": "$_id", "_id": 0}})

## Indexes

    use news;
    db.posts.ensureIndex({ "pubDate": 1 });
    db.posts.ensureIndex({ "category": 1 });
    db.posts.ensureIndex({ "origId": 1 }, { "unique": true });
db.posts.ensureIndex({ "title": "text" });
db.posts.ensureIndex({ "text": "text" });
    db.posts.getIndexes();

## Move DB posts to local

    ssh leetnews@marsgpl 'docker exec -t leetnews_mongo_1 mongoexport --uri="mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin" --collection=posts --out=/data/db/posts.json'

    scp leetnews@marsgpl:/home/leetnews/mongo-data/posts.json mongo-data/

    ssh root@marsgpl 'rm /home/leetnews/mongo-data/posts.json'

    docker exec -t leetnews_mongo_1 mongoimport --uri="mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin" --collection=posts --file=/data/db/posts.json --drop
