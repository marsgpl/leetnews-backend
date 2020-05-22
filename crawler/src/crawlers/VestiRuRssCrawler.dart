import '../RssCrawler.dart';

class VestiRuRssCrawler extends RssCrawler {
    String defaultLang = 'ru';
    String defaultCategory = 'Россия';
    String origName = 'vesti.ru';
    String rssFeed = 'https://www.vesti.ru/vesti.rss';
    bool removeUrlQueryInGuid = false;
}
