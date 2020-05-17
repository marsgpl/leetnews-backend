import 'package:mongo_dart/mongo_dart.dart';

import './Perf.dart';
import './Context.dart';
import './entities/Post.dart';

import './crawlers/RbcRuRssCrawler.dart';
import './crawlers/LifeRuRssCrawler.dart';
import './crawlers/LentaRuRssCrawler.dart';
import './crawlers/RussianRtComRssCrawler.dart';
import './crawlers/NewsYandexRuRssCrawler.dart';
import './crawlers/NewsRamblerRuRssCrawler.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin&appName=crawler';
const DELAY_BETWEEN_ITERATIONS_SECONDS = 60 * 5;

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    print('Mongo ready');

    final posts = mongo.collection('posts');

    final crawlers = [
        RbcRuRssCrawler(),
        LifeRuRssCrawler(),
        LentaRuRssCrawler(),
        RussianRtComRssCrawler(),
        NewsYandexRuRssCrawler(),
        NewsRamblerRuRssCrawler(),
    ];

    while (true) {
        Perf.start();
            final context = Context();
            final crawled = await Future.wait(crawlers.map((crawler) => crawler.crawl(context)));
            await insertPosts(posts, crawled);
        Perf.end('Iteration time');

        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}

Future<void> insertPosts(DbCollection posts, List<List<Post>> crawled) async {
    for (final list in crawled) {
        for (final post in list) {
            final existingRow = await getPostByOrigId(posts, post.origId);

            if (existingRow != null) {
                await mergePostWithRow(posts, post, existingRow);
            } else {
                post.pubDate = await preparePostPubDate(posts, post.pubDate);
                await posts.insert(post.toMongo());
            }
        }
    }
}

Future<Map<String, dynamic>> getPostByOrigId(DbCollection posts, String origId) =>
    posts.findOne(where.eq('origId', origId).limit(1));

Future<void> mergePostWithRow(
    DbCollection posts,
    Post altPost,
    Map<String, dynamic> mainRow,
) async {
    if (mainRow == null || altPost == null) return;

    bool postChanged = false;

    if ((mainRow['title'] ?? '').length < altPost.title.length) {
        mainRow['title'] = altPost.title;
        postChanged = true;
    }

    if ((mainRow['author'] ?? '').length < altPost.author.length) {
        mainRow['author'] = altPost.author;
        postChanged = true;
    }

    if ((mainRow['text'] ?? '').length < altPost.text.length) {
        mainRow['text'] = altPost.text;
        postChanged = true;
    }

    if ((mainRow['imgUrl'] ?? '').length < altPost.imgUrl.length) {
        mainRow['imgUrl'] = altPost.imgUrl;
        mainRow['imgMime'] = altPost.imgMime;
        postChanged = true;
    }

    if ((mainRow['category'] ?? '').length != altPost.category.length && altPost.category != 'Россия') {
        mainRow['category'] = altPost.category;
        postChanged = true;
    }

    if (postChanged) {
        await posts.save(mainRow);
    }
}

Future<DateTime> preparePostPubDate(DbCollection posts, DateTime pubDate) async {
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
        .sortBy('pubDate', descending: true)
        .limit(1);

    final row = await posts.findOne(selector);

    if (row == null) {
        return pubDate;
    } else {
        return row['pubDate'].add(const Duration(milliseconds: 1));
    }
}
