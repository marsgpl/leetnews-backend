import 'package:mongo_dart/mongo_dart.dart';

import './crawlers/LentaRuCrawler.dart';

const DELAY_BETWEEN_ITERATIONS_SECONDS = 60;

Future<void> main() async {
    Db news = Db('mongodb://mongo:27017/news');

    // await news.open();

    final crawlers = [
        LentaRuCrawler(news),
    ];

    while (true) {
        await Future.wait(crawlers.map((crawler) => crawler.crawl()));
        await Future.delayed(const Duration(seconds: DELAY_BETWEEN_ITERATIONS_SECONDS));
    }
}
