import 'package:mongo_dart/mongo_dart.dart';

import './crawlers/RbcRuRssCrawler.dart';
import './crawlers/LentaRuRssCrawler.dart';
import './crawlers/RussianRtComRssCrawler.dart';
import './crawlers/NewsYandexRuRssCrawler.dart';
import './crawlers/NewsRamblerRuRssCrawler.dart';
import './entities/Post.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin&appName=crawler';
const DELAY_BETWEEN_ITERATIONS_SECONDS = 60 * 5;

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();

    print('Mongo ready');

    // await dedupPostsByOrigId(mongo);

    final crawlers = [
        RbcRuRssCrawler(mongo),
        LentaRuRssCrawler(mongo),
        RussianRtComRssCrawler(mongo),
        NewsYandexRuRssCrawler(mongo),
        NewsRamblerRuRssCrawler(mongo),
    ];

    while (true) {
        final latestPost = await getLatestPost(mongo);

        final inserted = await Future.wait(crawlers.map((crawler) => crawler.crawl(latestPost)));

        if (inserted.fold(0, (a, b) => a + b) > 0) {
            await fixSamePubDates(mongo, latestPost);
        }

        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}

Future<Post> getLatestPost(Db mongo) async {
    final posts = mongo.collection('posts');

    final selector = where
        .sortBy('pubDate', descending: true)
        .limit(1);

    final row = await posts.findOne(selector);

    return row == null ?
        Post(pubDate: DateTime.now()) :
        Post.fromMongo(row);
}

Future<void> fixSamePubDates(Db mongo, Post latestPost) async {
    final posts = mongo.collection('posts');

    final digDateLimit = DateTime.now().subtract(Duration(days: 7));

    if (latestPost.pubDate.isBefore(digDateLimit)) {
        latestPost.pubDate = digDateLimit;
    }

    final pipeline = AggregationPipelineBuilder()
// .addStage(Match(where.gte('pubDate', latestPost.pubDate).map['\$query']))
        .addStage(Group(
            id: Field('pubDate'),
            fields: {
                'count': Sum(1),
            },
        ))
        .addStage(Match(where.gt('count', 1).map['\$query']))
        .addStage(Project({
            '_id': 0,
            'pubDate': '\$_id',
        }))
        .build();

    final result = await posts
        .aggregateToStream(pipeline)
        .toList();

    List<Future> tasks = [];

    for (final rec in result) {
        tasks.add(fixSamePubDate(mongo, rec['pubDate']));
    }

    if (tasks.length > 0) {
        await Future.wait(tasks);
    }
print('total tasks done: ${tasks.length}');
}

Future<void> fixSamePubDate(Db mongo, DateTime pubDate) async {
    final posts = mongo.collection('posts');

    final dateFrom = DateTime(
        pubDate.year,
        pubDate.month,
        pubDate.day,
        pubDate.hour,
        pubDate.minute,
        pubDate.second,
        0,
        0,
    );

    final dateTo = dateFrom.add(Duration(seconds: 1));

    final selector = where
        .gte('pubDate', dateFrom)
        .lt('pubDate', dateTo)
        .sortBy('pubDate', descending: false);

    final rows = await posts.find(selector).toList();

    List<Future> tasks = [];
    int deltaMs = 0;

    for (final row in rows) {
        row['pubDate'] = dateFrom.add(Duration(milliseconds: deltaMs++));
        tasks.add(posts.save(row));
    }

    if (tasks.length > 0) {
        await Future.wait(tasks);
    }
}

Future<void> dedupPostsByOrigId(Db mongo) async {
    final posts = mongo.collection('posts');

    print('> deduping posts by orig id');

    print('posts before: ${await posts.count()}');

    final pipeline = AggregationPipelineBuilder()
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

    final result = await posts
        .aggregateToStream(pipeline)
        .toList();

    int dupRecsTotal = 0;
    int dupIdsTotal = 0;
    List<ObjectId> dupIdsToRemove = [];

    for (final rec in result) {
        dupRecsTotal++;
        dupIdsTotal += rec['count'];

        for (int i = 1, c = rec['count']; i < c; ++i) {
            dupIdsToRemove.add(rec['ids'][i]);
        }
    }

    print('dupRecsTotal: $dupRecsTotal');
    print('dupIdsTotal: $dupIdsTotal');
    print('dupIdsToRemove: ${dupIdsToRemove.length}');

    await posts.remove(where.oneFrom('_id', dupIdsToRemove));

    print('posts after: ${await posts.count()}');
}
