import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html;

import '../entities/Post.dart';

class RssCrawler {
    RssCrawler(this.mongo);

    Db mongo;
    String rssFeed;
    String origName;

    RegExp htmlAnchor = RegExp(r'<a .*?</a>');

    Future<void> crawl() async {
        try {
            final newPosts = await getPosts();

            if (newPosts.length == 0) {
                throw Exception('$origName: newPosts.length == 0');
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
            print('$origName: crawl failed: $error');
        }
    }

    Future<List<Post>> getPosts() async {
        HttpClient client = HttpClient();
        final request = await client.getUrl(Uri.parse('$rssFeed?v=${DateTime.now()}'));
        final response = await request.close();

        final List<String> responseChunks = [];
        await utf8.decoder.bind(response).forEach(responseChunks.add);
        final feed = xml.parse(responseChunks.join(''));

        return convertFeedToPosts(feed);
    }

    List<Post> convertFeedToPosts(xml.XmlDocument feed) {
        return [];
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
    DateTime parsePubDate(String rssDateFmt) {
        if (rssDateFmt.length == 0) return DateTime.now();
        final parts = rssDateFmt.trim().split(' ');
        return DateTime.parse(
            '${parts[3]}-${monthNameToNumber(parts[2])}-${parts[1]}T${parts[4]}${parts[5]}');
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
