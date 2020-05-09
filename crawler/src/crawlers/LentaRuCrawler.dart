import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;

import '../../../api/src/entities/Post.dart';

class LentaRuCrawler {
    LentaRuCrawler(this.news);

    final Db news;

    Future<void> crawl() async {
        try {
            final request = await HttpClient().get('lenta.ru', 80, '/rss/articles');
            final response = await request.close();
            final List<String> responseChunks = [];
            await utf8.decoder.bind(response).forEach(responseChunks.add);
            final feed = xml.parse(responseChunks.join(''));
            final List<Post> posts = [];

            feed.findElements('rss').forEach((rss) {
                rss.findElements('channel').forEach((channel) {
                    final lang = channel.findElements('language').single.text;

                    channel.findElements('item').forEach((item) {
                        final guid = item.findElements('guid');
                        final origId = guid.isEmpty ? '' : guid.single.text;
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
                            title: title.isEmpty ? '' : title.single.text,
                            text: parseDescription(description.isEmpty ? '' : description.single.text),
                            author: author.isEmpty ? '' : author.single.text,
                            category: category.isEmpty ? '' : category.single.text,
                            imgUrl: enclosure.isEmpty ? '' : parseImgUrl(enclosure.single.attributes),
                            imgMime: enclosure.isEmpty ? '' : parseImgMime(enclosure.single.attributes),
                            lang: lang,
                            origId: origId,
                            origLink: link.isEmpty ? '' : link.single.text,
                        ));
                    });
                });
            });

            print('posts found: ${posts.length}');
            print('posts: $posts');
        } catch (error) {
            print('LentaRuCrawler failed: $error');
        }
    }

    String parseImgUrl(dynamic attributes) {
        for (final attribute in attributes) {
            if (attribute.name == 'url') return attribute.value;
        }

        return '';
    }

    String parseImgMime(dynamic attributes) {
        for (final attribute in attributes) {
            if (attribute.name == 'type') return attribute.value;
        }

        return '';
    }

    // Sat, 09 May 2020 19:51:00 +0300 -> 2002-02-27T14:00:00-0500
    DateTime parsePubDate(String lentaDateFmt) {
        final parts = lentaDateFmt.split(' ');
        return DateTime.parse('${parts[3]}-${monthNameToNumber(parts[2])}-${parts[1]}T${parts[4]}${parts[5]}');
    }

    // May -> 05
    String monthNameToNumber(String monthName) {
        switch (monthName) {
            case 'Jan': return '01';
            case 'Feb': return '02';
            case 'Mar': return '03';
            case 'Apr': return '04';
            case 'May': return '05';
            case 'Jun': return '06';
            case 'Jul': return '07';
            case 'Aug': return '08';
            case 'Sep': return '09';
            case 'Oct': return '10';
            case 'Nov': return '11';
            case 'Dec': return '12';
            default: return '01';
        }
    }

    String parseDescription(String raw) {
        return raw
            .replaceAll('<![CDATA[', '')
            .replaceAll(']]>', '')
            .trim();
    }
}
