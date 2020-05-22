import '../RssCrawler.dart';

class NewsMailRuRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'news.mail.ru';
    List<String> rssFeeds = [
        'https://news.mail.ru/rss',
        'https://news.mail.ru/rss/main',
    ];
}
