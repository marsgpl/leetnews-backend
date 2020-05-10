import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;

import '../entities/Post.dart';

const RSS_FEED = 'http://lenta.ru/rss/news';
const ORIG_NAME = 'lenta.ru';

class LentaRuCrawler {
    LentaRuCrawler(this.mongo);

    final Db mongo;

    Future<void> crawl() async {
        try {
            final newPosts = await getPosts();

            if (newPosts.length == 0) {
                throw Exception('newPosts.length == 0');
            }

            final postsColl = mongo.collection('posts');

            List<String> origIds = newPosts.map((post) => post.origId).toList();

            final existingPosts = postsColl
                .find(where.oneFrom('origId', origIds).fields(['origId']));

            final Map<String, bool> existingOrigIds = {};

            await existingPosts.forEach((post) {
                existingOrigIds[post['origId']] = true;
            });

            List<Map<String, dynamic>> postsToInsert = [];

            newPosts.forEach((post) {
                if (existingOrigIds[post.origId] != null) {
                    return;
                }

                postsToInsert.add(post.toMongo());
            });

            if (postsToInsert.length > 0) {
                await postsColl.insertAll(postsToInsert);
            }
        } catch (error) {
            print('LentaRuCrawler failed: $error');
        }
    }

    Future<List<Post>> getPosts() async {
        HttpClient client = HttpClient();
        final request = await client.getUrl(Uri.parse('$RSS_FEED?v=${DateTime.now()}'));
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
                        origName: ORIG_NAME,
                    ));
                });
            });
        });

        return posts;
    }

    String parseImgUrl(dynamic attributes) {
        for (final attribute in attributes) {
            if (attribute.name.toString() == 'url') {
                return attribute.value.toString();
            }
        }

        return '';
    }

    String parseImgMime(dynamic attributes) {
        for (final attribute in attributes) {
            if (attribute.name.toString() == 'type') {
                return attribute.value.toString();
            }
        }

        return '';
    }

    // Sat, 09 May 2020 19:51:00 +0300 -> 2002-02-27T14:00:00-0500
    DateTime parsePubDate(String lentaDateFmt) {
        if (lentaDateFmt.length == 0) return DateTime.now();
        final parts = lentaDateFmt.split(' ');
        return DateTime.parse('${parts[3]}-${monthNameToNumber(parts[2])}-${parts[1]}T${parts[4]}${parts[5]}');
    }

    // May -> 05
    String monthNameToNumber(String monthName) {
        switch (monthName.toLowerCase()) {
            case 'jan': return '01';
            case 'feb': return '02';
            case 'mar': return '03';
            case 'apr': return '04';
            case 'may': return '05';
            case 'jun': return '06';
            case 'jul': return '07';
            case 'aug': return '08';
            case 'sep': return '09';
            case 'oct': return '10';
            case 'nov': return '11';
            case 'dec': return '12';
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
