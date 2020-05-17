import 'package:xml/xml.dart' as xml;

import '../entities/Post.dart';
import './RssCrawler.dart';

class RussianRtComRssCrawler extends RssCrawler {
    String origName = 'russian.rt.com';
    String rssFeed = 'http://russian.rt.com/rss';

    List<Post> convertRssFeedToPosts(xml.XmlDocument feed) {
        final List<Post> candidates = [];

        feed.findElements('rss').forEach((rss) {
            rss.findElements('channel').forEach((channel) {
                final lang = parseLang(channel.findElements('language').single.text);

                channel.findElements('item').forEach((item) {
                    final description = item.findElements('description');
                    final enclosure = item.findElements('enclosure');
                    final category = item.findElements('category');
                    final pubDate = item.findElements('pubDate');
                    final author = item.findElements('dc:creator');
                    final title = item.findElements('title');
                    final link = item.findElements('link');
                    final guid = item.findElements('guid');

                    candidates.add(Post(
                        lang: lang,
                        origName: origName,
                        origId: parseGuid(guid.isEmpty ? '' : guid.single.text, removeUrlQuery: true),
                        origLink: parseLink(link.isEmpty ? '' : link.single.text),
                        pubDate: parsePubDate(pubDate.isEmpty ? '' : pubDate.single.text),
                        title: parseTitle(title.isEmpty ? '' : title.single.text),
                        text: parseDescription(description.isEmpty ? '' : description.single.text),
                        author: parseAuthor(author.isEmpty ? '' : author.single.text),
                        category: parseCategory(category.isEmpty ? '' : category.single.text),
                        imgUrl: enclosure.isEmpty ? '' : parseImgUrl(enclosure.single.attributes),
                        imgMime: enclosure.isEmpty ? '' : parseImgMime(enclosure.single.attributes),
                    ));
                });
            });
        });

        return candidates;
    }
}
