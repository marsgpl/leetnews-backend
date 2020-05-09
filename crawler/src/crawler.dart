import 'package:mongo_dart/mongo_dart.dart';

import './crawlers/LentaRuCrawler.dart';

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
        await Future.wait(crawlers.map((crawler) => crawler.crawl()));
        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}
