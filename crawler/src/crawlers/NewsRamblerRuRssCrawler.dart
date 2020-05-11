import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;

import '../entities/Post.dart';
import './RssCrawler.dart';

class NewsRamblerRuRssCrawler extends RssCrawler {
    NewsRamblerRuRssCrawler(Db mongo) : super(mongo);

    List<String> rssFeeds = [
        'http://news.rambler.ru/rss/world/',
        'http://news.rambler.ru/rss/moscow_city/',
        'http://news.rambler.ru/rss/politics/',
        'http://news.rambler.ru/rss/community/',
        'http://news.rambler.ru/rss/incidents/',
        'http://news.rambler.ru/rss/tech/',
        'http://news.rambler.ru/rss/starlife/',
        'http://news.rambler.ru/rss/army/',
    ];

    String origName = 'news.rambler.ru';

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
                final lang = channel.findElements('language').single.text.trim().toLowerCase();

                channel.findElements('item').forEach((item) {
                    final guid = item.findElements('guid');
                    final origId = parseGuid(guid.isEmpty ? '' : guid.single.text);
                    if (origId.length == 0) return;

                    final description = item.findElements('description');
                    final enclosure = item.findElements('enclosure');
                    final category = item.findElements('category');
                    final pubDate = item.findElements('pubDate');
                    final author = item.findElements('author');
                    final title = item.findElements('title');
                    final link = item.findElements('link');

                    posts.add(Post(
                        pubDate: parsePubDate(pubDate.isEmpty ? '' : pubDate.single.text),
                        title: parseTitle(title.isEmpty ? '' : title.single.text),
                        text: parseDescription(description.isEmpty ? '' : description.single.text),
                        author: parseAuthor(author.isEmpty ? '' : author.single.text),
                        category: parseCategory(category.isEmpty ? '' : category.single.text),
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
