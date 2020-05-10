import 'package:mongo_dart/mongo_dart.dart';

import './crawlers/LentaRuCrawler.dart';
import './entities/Post.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/admin';
const MONGO_DB = 'news';
const DELAY_BETWEEN_ITERATIONS_SECONDS = 60 * 5;

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    mongo.databaseName = MONGO_DB;

    print('Mongo ready');

    final crawlers = [
        LentaRuCrawler(mongo),
    ];

    while (true) {
        final latestPost = await getLatestPost(mongo);
        await Future.wait(crawlers.map((crawler) => crawler.crawl()));
        await fixSamePubDates(mongo, latestPost);
        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}

Future<void> fixSamePubDates(Db mongo, Post latestPost) async {
    final postsColl = mongo.collection('posts');
    final selector = where;

    if (latestPost != null) {
        selector.gte('pubDate', latestPost.pubDate);
    }

    selector
        .sortBy('pubDate', descending: false)
        .limit(9999);

    final rows = await postsColl
        .find(selector)
        .toList();

    if (rows.length < 2) return;

    DateTime latest;
    int deltaMs;

    List<Future> tasks = [];

    rows.forEach((row) {
        DateTime current = row['pubDate'];

        if (latest == null || !latest.isAtSameMomentAs(current)) {
            latest = current;
            deltaMs = 0;
        } else {
            row['pubDate'] = current.add(Duration(milliseconds: ++deltaMs));
            tasks.add(postsColl.save(row));
        }
    });

    if (tasks.length > 0) {
        await Future.wait(tasks);
    }
}

Future<Post> getLatestPost(Db mongo) async {
    final postsColl = mongo.collection('posts');
    final selector = where
        .sortBy('pubDate', descending: true)
        .limit(1);

    final row = await postsColl
        .findOne(selector);

    return row == null ? null : Post.fromMongo(row);
}
