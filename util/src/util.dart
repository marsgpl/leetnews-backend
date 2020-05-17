import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import './Perf.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin&appName=util';
const DELAY_BETWEEN_ITERATIONS_SECONDS = 60 * 9;

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    print('Mongo ready');

    final posts = mongo.collection('posts');

    // await showPostsIndexes(posts);
    // await fixPostsOrigId(posts);
    // await fixPostsCategory(posts);
    // await dedupPostsPubDates(posts);

    while (true) {
        Perf.start();
            await mergePosts(posts);
        Perf.end('Iteration time');

        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}

Future<void> fixPostsCategory(DbCollection posts) async {
    print('Fixing posts category ...');

    final selector = where.eq('category', '').or(where.eq('category', null));

    print('Count before: ${await posts.count(selector)}');

    await posts.update(selector, modify.set('category', 'Россия'));

    print('Count after: ${await posts.count(selector)}');
    print('OK');
}

Future<void> fixPostsOrigId(DbCollection posts) async {
    print('Fixing posts origId ...');

    final selector = where
        .oneFrom('origName', ['news.yandex.ru', 'russian.rt.com'])
        .sortBy('pubDate', descending: false);

    final urlQueryRemover = RegExp(r'\?.*?$', multiLine: true, dotAll: true);

    int processed = 0;

    print('Count: ${await posts.count(selector)}');

    final rows = posts.find(selector);

    await for (final row in rows) {
        final oldOrigId = row['origId'];
        final newOrigId = oldOrigId.replaceAll(urlQueryRemover, '');

        if (newOrigId != oldOrigId) {
            row['origId'] = newOrigId;

            try {
                await posts.save(row);
            } catch (error) {
                if (error['code'] == 11000) {
                    print('Dup origId: $newOrigId');
                    final existingRow = await getPostByOrigId(posts, newOrigId);
                    await mergePostWithRow(posts, row, existingRow);
                    await posts.remove(where.id(row['_id']));
                } else {
                    print(error);
                    exit(1);
                }
            }
        }

        processed++;
    }

    print('Processed: $processed');
    print('OK');
}

Future<Map<String, dynamic>> getPostByOrigId(DbCollection posts, String origId) =>
    posts.findOne(where.eq('origId', origId).limit(1));

Future<void> mergePostWithRow(
    DbCollection posts,
    Map<String, dynamic> altRow,
    Map<String, dynamic> mainRow,
) async {
    if (mainRow == null || altRow == null) return;

    bool postChanged = false;

    if ((mainRow['title'] ?? '').length < (altRow['title'] ?? '').length) {
        mainRow['title'] = altRow['title'];
        postChanged = true;
    }

    if ((mainRow['author'] ?? '').length < (altRow['author'] ?? '').length) {
        mainRow['author'] = altRow['author'];
        postChanged = true;
    }

    if (!postRowHasText(mainRow) && postRowHasText(altRow)) {
        mainRow['text'] = altRow['text'];
        postChanged = true;
    }

    if (!postRowHasImg(mainRow) && postRowHasImg(altRow)) {
        mainRow['imgUrl'] = altRow['imgUrl'];
        mainRow['imgMime'] = altRow['imgMime'];
        postChanged = true;
    }

    if (!postRowHasCategory(mainRow) && postRowHasCategory(altRow)) {
        mainRow['category'] = altRow['category'];
        postChanged = true;
    }

    if (postChanged) {
        print('Dup origId merging posts: ${mainRow['_id']} + ${altRow['_id']}');
        await posts.save(mainRow);
    }
}

Future<void> mergePosts(DbCollection posts) async {
    print('Merging posts ...');
    final postsCountBefore = await posts.count();
    print('Posts before: ${postsCountBefore}');

    int processed = 0;
    final DateTime pubDateBottomEdge = DateTime.now().subtract(const Duration(days: 1));

    SelectorBuilder selector = where
        .gt('pubDate', pubDateBottomEdge)
        .sortBy('pubDate', descending: true)
        .limit(1);

    while (true) {
        final row = await posts.findOne(selector);
        if (row == null) break;

        await mergePost(posts, row);
        processed++;

        selector = where
            .gt('pubDate', pubDateBottomEdge)
            .lt('pubDate', row['pubDate'])
            .sortBy('pubDate', descending: true)
            .limit(1);
    }

    print('Posts processed: ${processed}');
    print('Posts after: $postsCountBefore -> ${await posts.count()}');
    print('OK');
}

bool postRowHasText(Map<String, dynamic> row) =>
    row['text'] != null && row['text'].trim().length > 0;

bool postRowHasImg(Map<String, dynamic> row) =>
    row['imgUrl'] != null && row['imgUrl'].trim().length > 0;

bool postRowHasCategory(Map<String, dynamic> row) =>
    row['category'] != null && row['category'].trim().length > 0 &&
    row['category'] != 'Россия'; // rbc and rt does not provide category so we put 'Россия'

Future<void> mergePost(
    DbCollection posts,
    Map<String, dynamic> postRow,
) async {
    final id = postRow['_id'];
    final title = (postRow['title'] ?? '').trim();
    bool hasText = postRowHasText(postRow);
    bool hasImg = postRowHasImg(postRow);
    bool hasCategory = postRowHasCategory(postRow);
    bool postChanged = false;
    int removedPostsCount = 0;
    double etalonScore;

    if (title.length == 0) {
        print('Post removed: empty title: $id');
        await posts.remove(where.id(id));
        return;
    }

    final selector = where.eq('\$text', {
            '\$search': title,
            '\$caseSensitive': false,
        })
            .metaTextScore('score')
            .sortByMetaTextScore('score')
            .limit(5)
            .fields([
                'title',
                'text',
                'imgUrl',
                'imgMime',
                'category',
            ]);

    while (true) {
        final rows = posts.find(selector);

        List<ObjectId> idsToDelete = [];
        int processedPostsCount = 0;
        bool stop = false;

        await for (final row in rows) {
            processedPostsCount++;

            final score = row['score'];

            if (etalonScore == null) {
                etalonScore = score;
            } else if (score / etalonScore < 1) {
                // to detect difference deeper than 1 we need analysis
                stop = true;
            } else {
                idsToDelete.add(row['_id']);

                if (title.length < (row['title'] ?? '').length) {
                    postRow['title'] = row['title'];
                    postChanged = true;
                }

                if ((postRow['author'] ?? '').length < (row['author'] ?? '').length) {
                    postRow['author'] = row['author'];
                    postChanged = true;
                }

                if ((!hasText && postRowHasText(row)) || (postRow['text'] ?? '').length < (row['text'] ?? '').length) {
                    postRow['text'] = row['text'];
                    hasText = true;
                    postChanged = true;
                }

                if (!hasImg && postRowHasImg(row)) {
                    postRow['imgUrl'] = row['imgUrl'];
                    postRow['imgMime'] = row['imgMime'];
                    hasImg = true;
                    postChanged = true;
                }

                if (!hasCategory && postRowHasCategory(row)) {
                    postRow['category'] = row['category'];
                    hasCategory = true;
                    postChanged = true;
                }
            }
        };

        await posts.remove(where.oneFrom('_id', idsToDelete));
        removedPostsCount += idsToDelete.length;

        if (stop || processedPostsCount < 2) break;
    }

    if (postChanged) {
        await posts.save(postRow);
    }

    // print('${postRow['pubDate']}    ${removedPostsCount > 0 ? removedPostsCount : '.'}${postChanged ? ' yes' : ''}');
}

Future<void> dedupPostsPubDates(DbCollection posts) async {
    print('Dedup posts pubDates ...');

    final pipeline = AggregationPipelineBuilder()
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

    int dups = 0;

    final records = posts.aggregateToStream(pipeline);

    await for (final rec in records) {
        await dedupPostPubDate(posts, rec['pubDate']);
        dups++;
    }

    print('Duped pubDates: $dups');
    print('OK');
}

Future<void> dedupPostPubDate(DbCollection posts, DateTime pubDate) async {
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

    final dateTo = dateFrom.add(const Duration(seconds: 1));

    final selector = where
        .gte('pubDate', dateFrom)
        .lt('pubDate', dateTo)
        .sortBy('pubDate', descending: false);

    final rows = posts.find(selector);

    List<Future> tasks = [];
    int deltaMs = 0;

    await for (final row in rows) {
        row['pubDate'] = dateFrom.add(Duration(milliseconds: deltaMs++));
        tasks.add(posts.save(row));
    };

    if (tasks.length > 0) {
        await Future.wait(tasks);
    }
}

Future<void> showPostsIndexes(DbCollection posts) async {
    print('Indexes:');

    final indexes = await posts.getIndexes();
    final indent = '    ';

    for (final index in indexes) {
        print('$indent${index['name']}:');
        for (final key in index.keys) {
            if (key == 'name') continue;
            print('$indent$indent$key: ${index[key]}');
        }
    }
}
