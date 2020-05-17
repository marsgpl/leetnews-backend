import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html;

import '../Context.dart';
import '../entities/Post.dart';

abstract class RssCrawler {
    final htmlAnchor = RegExp(r'<a .*?</a>',
        multiLine: true,
        caseSensitive: false,
        dotAll: true);

    final urlQueryRemover = RegExp(r'\?.*?$',
        multiLine: true,
        dotAll: true);

    String origName;
    String rssFeed;
    List<String> rssFeeds;

    Future<List<Post>> crawl(Context context) async {
        try {
            return (await getPosts()).where((post) {
                if (context.postsOrigIdCache[post.origId] != null) {
                    return false;
                }

                context.postsOrigIdCache[post.origId] = true;

                if (post.title.length == 0) {
                    return false;
                }

                if (post.category.length == 0) {
                    post.category = 'Россия';
                }

                return true;
            }).toList();
        } catch (error) {
            print('$origName: crawl failed: $error');
            return [];
        }
    }

    Future<List<Post>> getPosts() async {
        if (rssFeed != null) {
            return convertRssFeedToPosts(await crawlRssFeed(rssFeed));
        } else if (rssFeeds != null) {
            List<Post> candidates = [];

            final feeds = await Future.wait(rssFeeds.map(crawlRssFeed));
            final candidatesMap = feeds.map(convertRssFeedToPosts);

            for (final candidatesChunk in candidatesMap) {
                candidates += candidatesChunk;
            }

            return candidates;
        } else {
            throw Exception('rssFeed and rssFeeds are null');
        }
    }

    List<Post> convertRssFeedToPosts(xml.XmlDocument feed);

    Future<xml.XmlDocument> crawlRssFeed(String feed) async {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(feed));
        final response = await request.close();
        final List<String> responseChunks = await utf8.decoder.bind(response).toList();
        return xml.parse(responseChunks.join(''));
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
    // 09 May 2020 04:39:00 +0000
    // Fri, 15 May 2020 10:23:44 GMT
    DateTime parsePubDate(String rssDateFmt) {
        if (rssDateFmt.length == 0) return DateTime.now();

        final parts = rssDateFmt.trim().split(' ');

        String tz = parts[parts.length - 1]; // +0300
        String hms = parts[parts.length - 2]; // 04:39:00
        String year = parts[parts.length - 3]; // 2020
        String monthName = parts[parts.length - 4]; // May
        String day = parts[parts.length - 5]; // 09

        if (tz == 'GMT') {
            tz = '+0000';
        }

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

    String parseGuid(String text, { bool removeUrlQuery = false }) {
        text = removeCdata(text).trim();

        if (removeUrlQuery) {
            text = text.replaceAll(urlQueryRemover, '');
        }

        return text.length > 0 ? text : DateTime.now().toIso8601String();
    }

    String parseLink(String text) =>
        removeCdata(text).trim();

    String parseAuthor(String text) =>
        removeCdata(text).trim();

    String parseCategory(String text) =>
        removeCdata(text).trim();

    String parseLang(String text) =>
        removeCdata(text).trim().toLowerCase();
}
