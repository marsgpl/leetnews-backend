import '../RssCrawler.dart';

class NewsruComRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'newsru.com';
    String rssFeed = 'https://rss.newsru.com/all_news';
}
