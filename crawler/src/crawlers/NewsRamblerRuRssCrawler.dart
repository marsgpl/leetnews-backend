import '../RssCrawler.dart';

class NewsRamblerRuRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'news.rambler.ru';
    List<String> rssFeeds = [
        'https://news.rambler.ru/rss/world/',
        'https://news.rambler.ru/rss/moscow_city/',
        'https://news.rambler.ru/rss/politics/',
        'https://news.rambler.ru/rss/community/',
        'https://news.rambler.ru/rss/incidents/',
        'https://news.rambler.ru/rss/tech/',
        'https://news.rambler.ru/rss/starlife/',
        'https://news.rambler.ru/rss/army/',
    ];
}
