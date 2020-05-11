import 'package:mongo_dart/mongo_dart.dart';

import './crawlers/RbcRuRssCrawler.dart';
import './crawlers/LentaRuRssCrawler.dart';
import './crawlers/RussianRtComRssCrawler.dart';
import './crawlers/NewsYandexRuRssCrawler.dart';
import './crawlers/NewsRamblerRuRssCrawler.dart';
import './entities/Post.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/admin';
const MONGO_DB = 'news';
const DELAY_BETWEEN_ITERATIONS_SECONDS = 60 * 5;

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    mongo.databaseName = MONGO_DB;

    print('Mongo ready');

    await dedupPosts(mongo);

    // final crawlers = [
    //     RbcRuRssCrawler(mongo),
    //     LentaRuRssCrawler(mongo),
    //     RussianRtComRssCrawler(mongo),
    //     NewsYandexRuRssCrawler(mongo),
    //     NewsRamblerRuRssCrawler(mongo),
    // ];

    // while (true) {
    //     final latestPost = await getLatestPost(mongo);
    //     await Future.wait(crawlers.map((crawler) => crawler.crawl(latestPost)));
    //     await fixSamePubDates(mongo, latestPost);
    //     await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    // }
}

// TODO: select only pubDate's duplicates
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

Future<void> dedupPosts(Db mongo) async {
    final postsColl = mongo.collection('posts');

    print('posts before: ${await postsColl.count()}');

    final pipeline = AggregationPipelineBuilder()
        .addStage(Match(where.ne('origId', null).map['\$query']))
        .addStage(Group(
            id: Field('origId'),
            fields: {
                'count': Sum(1),
                'ids': Push(Field('_id')),
            },
        ))
        .addStage(Match(where.gt('count', 1).map['\$query']))
        .addStage(Sort({ 'count': -1 }))
        .addStage(Project({
            '_id': 0,
            'origId': '\$_id',
            'count': '\$count',
            'ids': '\$ids',
        }))
        .build();

    final result = await postsColl.aggregateToStream(pipeline).toList();

    int dupRecsTotal = 0;
    int dupIdsTotal = 0;
    List<ObjectId> dupIdsToRemove = [];

    for (final rec in result) {
        dupRecsTotal++;
        dupIdsTotal += rec['ids'].length;

        for (int i = 0, c = rec['ids'].length - 1; i < c; ++i) {
            dupIdsToRemove.add(rec['ids'][i]);
        }
    }

    print('dupRecsTotal: $dupRecsTotal');
    print('dupIdsTotal: $dupIdsTotal');
    print('dupIdsToRemove: ${dupIdsToRemove.length}');

    await postsColl.remove(where.oneFrom('_id', dupIdsToRemove));

    print('posts after: ${await postsColl.count()}');
}
