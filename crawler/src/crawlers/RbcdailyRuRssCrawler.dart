import '../RssCrawler.dart';

class RbcdailyRuRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'rbcdaily.ru';
    String rssFeed = 'http://static.feed.rbc.ru/rbc/logical/footer/rbcdaily_last_issue.rss';
}
