import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;

import '../entities/Post.dart';
import './RssCrawler.dart';

class NewsYandexRuRssCrawler extends RssCrawler {
    NewsYandexRuRssCrawler(Db mongo) : super(mongo);

    List<String> rssFeeds = [
        'http://news.yandex.ru/auto.rss',
        'http://news.yandex.ru/auto_racing.rss',
        'http://news.yandex.ru/army.rss',
        'http://news.yandex.ru/basketball.rss',
        'http://news.yandex.ru/biathlon.rss',
        'http://news.yandex.ru/world.rss',
        'http://news.yandex.ru/volleyball.rss',
        'http://news.yandex.ru/gadgets.rss',
        'http://news.yandex.ru/index.rss',
        'http://news.yandex.ru/martial_arts.rss',
        'http://news.yandex.ru/communal.rss',
        'http://news.yandex.ru/health.rss',
        'http://news.yandex.ru/games.rss',
        'http://news.yandex.ru/internet.rss',
        'http://news.yandex.ru/cyber_sport.rss',
        'http://news.yandex.ru/movies.rss',
        'http://news.yandex.ru/koronavirus.rss',
        'http://news.yandex.ru/cosmos.rss',
        'http://news.yandex.ru/culture.rss',
        'http://news.yandex.ru/championsleague.rss',
        'http://news.yandex.ru/music.rss',
        'http://news.yandex.ru/nhl.rss',
        'http://news.yandex.ru/science.rss',
        'http://news.yandex.ru/realty.rss',
        'http://news.yandex.ru/society.rss',
        'http://news.yandex.ru/politics.rss',
        'http://news.yandex.ru/incident.rss',
        'http://news.yandex.ru/travels.rss',
        'http://news.yandex.ru/rpl.rss',
        'http://news.yandex.ru/religion.rss',
        'http://news.yandex.ru/sport.rss',
        'http://news.yandex.ru/theaters.rss',
        'http://news.yandex.ru/tennis.rss',
        'http://news.yandex.ru/computers.rss',
        'http://news.yandex.ru/vehicle.rss',
        'http://news.yandex.ru/figure_skating.rss',
        'http://news.yandex.ru/finances.rss',
        'http://news.yandex.ru/football.rss',
        'http://news.yandex.ru/hockey.rss',
        'http://news.yandex.ru/showbusiness.rss',
        'http://news.yandex.ru/ecology.rss',
        'http://news.yandex.ru/business.rss',
        'http://news.yandex.ru/energy.rss',
    ];

    String origName = 'news.yandex.ru';

    Future<List<Post>> getPosts() async {
        List<Post> posts = [];

        final feeds = await Future.wait(rssFeeds.map(crawlRssFeed));
        final postsList = feeds.map(convertRssFeedToPosts);

        for (final postList in postsList) {
            posts += postList;
        }

        return posts;
    }

    List<Post> convertRssFeedToPosts(xml.XmlDocument feed) {
        final List<Post> posts = [];

        feed.findElements('rss').forEach((rss) {
            rss.findElements('channel').forEach((channel) {
                final lang = 'ru';
                final category = channel.findElements('title').single.text.trim().split(': ')[1];

                channel.findElements('item').forEach((item) {
                    final guid = item.findElements('guid');
                    final origId = parseGuid(guid.isEmpty ? '' : guid.single.text);
                    if (origId.length == 0) return;

                    final description = item.findElements('description');
                    final enclosure = item.findElements('enclosure');
                    final pubDate = item.findElements('pubDate');
                    final author = item.findElements('author');
                    final title = item.findElements('title');
                    final link = item.findElements('link');

                    posts.add(Post(
                        pubDate: parsePubDate(pubDate.isEmpty ? '' : pubDate.single.text),
                        title: parseTitle(title.isEmpty ? '' : title.single.text),
                        text: parseDescription(description.isEmpty ? '' : description.single.text),
                        author: parseAuthor(author.isEmpty ? '' : author.single.text),
                        category: category,
                        imgUrl: enclosure.isEmpty ? '' : parseImgUrl(enclosure.single.attributes),
                        imgMime: enclosure.isEmpty ? '' : parseImgMime(enclosure.single.attributes),
                        lang: lang,
                        origId: origId,
                        origLink: parseLink(link.isEmpty ? '' : link.single.text),
                        origName: origName,
                    ));
                });
            });
        });

        return posts;
    }
}
