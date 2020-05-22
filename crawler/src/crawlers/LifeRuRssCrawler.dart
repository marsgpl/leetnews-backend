import '../RssCrawler.dart';

class LifeRuRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'life.ru';
    String rssFeed = 'http://api.prod2.corr.life/public/xml/feed.xml';
}
