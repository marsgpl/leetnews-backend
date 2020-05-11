import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html;

import '../entities/Post.dart';

abstract class RssCrawler {
    RssCrawler(this.mongo);

    Db mongo;
    String rssFeed;
    String origName;

    RegExp htmlAnchor = RegExp(r'<a .*?</a>');

    Future<void> crawl(Post latestPost) async {
        try {
            Map<String, bool> postIdCache = {};
            final newPosts = (await getPosts()).where((post) {
                if (postIdCache[post.origId] != null) return false;
                postIdCache[post.origId] = true;
                return true;
            }).toList();

            if (newPosts.length == 0) {
                throw Exception('$origName: newPosts.length == 0');
            }

            final postsColl = mongo.collection('posts');

            List<String> origIds = newPosts.map((post) => post.origId)
                .toList(growable: false);

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

                if (latestPost == null) {
                    latestPost = Post(pubDate: post.pubDate);
                } else if (post.pubDate.compareTo(latestPost.pubDate) < 0) {
                    latestPost.pubDate = post.pubDate;
                }

                postsToInsert.add(post.toMongo());
            });

            if (postsToInsert.length > 0) {
                await postsColl.insertAll(postsToInsert);
            }
        } catch (error) {
            print('$origName: crawl failed: $error');
        }
    }

    Future<List<Post>> getPosts() async {
        return convertRssFeedToPosts(await crawlRssFeed(rssFeed));
    }

    Future<xml.XmlDocument> crawlRssFeed(String feed) async {
        HttpClient client = HttpClient();
        final request = await client.getUrl(Uri.parse('$feed?v=${DateTime.now()}'));
        final response = await request.close();

        final List<String> responseChunks = [];
        await utf8.decoder.bind(response).forEach(responseChunks.add);
        return xml.parse(responseChunks.join(''));
    }

    List<Post> convertRssFeedToPosts(xml.XmlDocument feed);

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
    // 09 May 2020 04:39:00 +0000
    DateTime parsePubDate(String rssDateFmt) {
        if (rssDateFmt.length == 0) return DateTime.now();
        final parts = rssDateFmt.trim().split(' ');
        final tz = parts[parts.length - 1]; // +0300
        final hms = parts[parts.length - 2]; // 04:39:00
        final year = parts[parts.length - 3]; // 2020
        final monthName = parts[parts.length - 4]; // May
        final day = parts[parts.length - 5]; // 09

        return DateTime.parse('$year-${monthNameToNumber(monthName)}-${day}T$hms$tz');
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

    String removeHtmlTags(String text) =>
        html.parse(text.replaceAll(htmlAnchor, ''))
            .documentElement.text;

    String removeCdata(String text) => text
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '');

    String parseDescription(String text) =>
        removeHtmlTags(removeCdata(text)).trim();

    String parseTitle(String text) =>
        removeCdata(text).trim();

    String parseGuid(String text) =>
        removeCdata(text).trim();

    String parseLink(String text) =>
        removeCdata(text).trim();

    String parseAuthor(String text) =>
        removeCdata(text).trim();

    String parseCategory(String text) =>
        removeCdata(text).trim();
}
