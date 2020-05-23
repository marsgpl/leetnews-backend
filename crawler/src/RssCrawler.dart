import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html;
import 'package:html_unescape/html_unescape.dart';

import './Context.dart';
import './entities/Post.dart';
import './cp1251toUtf8.dart';
import './isAboutCovid.dart';

abstract class RssCrawler {
    final htmlAnchor = RegExp(r'<a .*?</a>',
        multiLine: true,
        caseSensitive: false,
        dotAll: true);

    final urlQueryRemover = RegExp(r'\?.*?$',
        multiLine: true,
        dotAll: true);

    final contentTypeSplitter = RegExp(r'\s*;\s*');

    final List<Pattern> categoriesOrganicSeparators = [
        RegExp(r'\s+и\s+', caseSensitive: false),
        RegExp(r'\s*[^a-z0-9а-яёЁ \-]+\s*', caseSensitive: false),
    ];

    final unescape = HtmlUnescape();

    bool removeUrlQueryInGuid = true;
    String defaultLang;
    String defaultCategory;
    String origName;
    String rssFeed;
    List<String> rssFeeds;

    Future<List<Post>> crawl(Context context) async {
        try {
            return (await getPosts()).where((post) {
                if (post.origId.length == 0) {
                    print('$origName: post.origId.length == 0');
                    return false;
                }

                if (post.title.length == 0) {
                    print('$origName: post.title.length == 0');
                    return false;
                }

                if (post.lang.length != 2) {
                    print('$origName: post.lang.length != 2');
                    return false;
                }

                if (post.category.length == 0) {
                    print('$origName: post.category.length == 0');
                    return false;
                }

                if (post.pubDate == null) {
                    print('$origName: post.pubDate == null');
                    return false;
                }

                if (context.postsOrigIdCache[post.origId] != null) return false;
                context.postsOrigIdCache[post.origId] = true;

                return true;
            }).toList();
        } catch (error, stacktrace) {
            print('$origName: crawl failed: $error\n$stacktrace');
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

    String getTagValue(xml.XmlElement element, String tagName) {
        final tag = element.findElements(tagName);
        return tag.isEmpty ? '' : removeCdata(tag.first.text).trim();
    }

    String parseChannelCategory(xml.XmlElement channel) {
        final category = getTagValue(channel, 'category');

        if (category.length > 0) {
            return category;
        }

        final title = getTagValue(channel, 'title');

        if (title.length > 0) {
            if (title.contains(': ')) {
                return title.split(': ')[1].trim();
            } else if (title.contains(' — ')) {
                title.split(' — ')[0].trim();
            }
        }

        return '';
    }

    String parseItemCategory(xml.XmlElement item) {
        final category = item.findElements('category');
        if (category.isEmpty) return '';

        Map<String, bool> candidates = {};

        category.forEach((item) {
            final value = removeCdata(item.text).trim();

            categoriesOrganicSeparators.firstWhere((pattern) {
                if (value.contains(pattern)) {
                    value.split(pattern).forEach((part) {
                        candidates[part] = true;
                    });
                    return true;
                }
                return false;
            }, orElse: () {
                candidates[value] = true;
                return null;
            });
        });

        return candidates.keys.toList(growable: false).join(', ');
    }

    String parseItemDescription(xml.XmlElement item) {
        final description = normalizeDescription(getTagValue(item, 'description'));
        final text = normalizeDescription(getTagValue(item, 'yandex:full-text'));

        return text.length > description.length ? text : description;
    }

    String parseItemAuthor(xml.XmlElement item) {
        final creator = getTagValue(item, 'dc:creator');
        final author = getTagValue(item, 'author');

        return creator.length > author.length ? creator : author;
    }

    DateTime parseItemPubDate(xml.XmlElement item) {
        return parsePubDate(getTagValue(item, 'pubDate'));
    }

    String parseItemTitle(xml.XmlElement item) {
        return getTagValue(item, 'title');
    }

    String parseItemLink(xml.XmlElement item) {
        return normalizeLink(getTagValue(item, 'link'));
    }

    String parseLang(xml.XmlElement element) {
        return normalizeLang(getTagValue(element, 'language'));
    }

    String parseItemGuid(xml.XmlElement item) {
        final guid = normalizeGuid(
            getTagValue(item, 'guid'),
            removeUrlQuery: removeUrlQueryInGuid);

        if (guid.length > 0) return guid;

        final link = normalizeGuid(
            getTagValue(item, 'link'),
            removeUrlQuery: removeUrlQueryInGuid);

        if (link.length > 0) return link;

        return DateTime.now().toIso8601String();
    }

    List<Post> convertRssFeedToPosts(xml.XmlDocument feed) {
        final List<Post> candidates = [];

        feed.findElements('rss').forEach((rss) {
            rss.findElements('channel').forEach((channel) {
                final channelLang = parseLang(channel);
                final channelCategory = parseChannelCategory(channel);

                channel.findElements('item').forEach((item) {
                    String lang = parseLang(item);
                    String category = parseItemCategory(item);

                    final enclosureEl = item.findElements('enclosure');

                    String imgUrl = '';
                    String imgMime = '';

                    if (!enclosureEl.isEmpty) {
                        for (final attribute in enclosureEl.first.attributes) {
                            if (attribute.name.toString() == 'url') {
                                imgUrl = normalizeLink(attribute.value.toString().trim());
                            } else if (attribute.name.toString() == 'type') {
                                imgMime = normalizeMime(attribute.value.toString().trim());
                            }
                        }
                    }

                    final title = parseItemTitle(item);
                    final text = parseItemDescription(item);
                    final author = parseItemAuthor(item);

                    lang = lang.length > 0 ?
                        lang :
                        channelLang.length > 0 ?
                            channelLang :
                            defaultLang ?? 'en';

                    category = category.length > 0 ?
                        category :
                        channelCategory.length > 0 ?
                            channelCategory :
                            defaultCategory ?? 'Generic';

                    final isCovid = isAboutCovid(title) ||
                        isAboutCovid(text) ||
                        isAboutCovid(category) ||
                        isAboutCovid(author);

                    candidates.add(Post(
                        lang: lang,
                        category: category,
                        origName: origName,
                        origId: parseItemGuid(item),
                        origLink: parseItemLink(item),
                        pubDate: parseItemPubDate(item),
                        title: title,
                        text: title == text ? '' : text,
                        author: author,
                        imgUrl: imgUrl,
                        imgMime: imgMime,
                        isCovid: isCovid,
                    ));
                });
            });
        });

        return candidates;
    }

    Future<xml.XmlDocument> crawlRssFeed(String feed) async {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(feed));
        final response = await request.close();
        final charset = detectResponseCharset(response.headers);

        if (response.redirects.length > 0) {
            print('$origName: redirects count > 0: ${response.redirects}');
        }

        if (charset == 'windows-1251' || charset == 'cp1251') {
            final chunk = await cp1251toUtf8(response);
            return xml.parse(chunk);
        } else { // utf-8
            final chunks = await utf8.decoder.bind(response).toList();
            return xml.parse(chunks.join(''));
        }
    }

    String detectResponseCharset(HttpHeaders headers) {
        String result = '';

        // application/rss+xml; charset=utf-8
        final mimes = headers['content-type'];

        if (mimes != null) {
            final mime = mimes.first;
            final parts = mime.split(contentTypeSplitter);
            final charset = parts
                .firstWhere((part) => part.contains('charset'), orElse: () => '')
                .trim();

            if (charset.length > 0) {
                result = charset.split('=').last;
            }
        }

        // utf-8
        final charsets = headers['content-charset'];

        if (charsets != null) {
            result = charsets.first;
        }

        return result
            .trim()
            .toLowerCase();
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

    // text.replaceAll(htmlAnchor, '')
    String removeHtmlTags(String text) =>
        html.parse(unescape.convert(text))
            .documentElement.text;

    String removeCdata(String text) => text
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '');

    String normalizeLang(String text) {
        final lang = text.toLowerCase();
        return lang.length > 2 ? lang.substring(0, 2) : lang;
    }

    String normalizeDescription(String text) =>
        removeHtmlTags(text);

    String normalizeGuid(String text, { bool removeUrlQuery = false }) {
        if (removeUrlQuery) {
            text = text.replaceAll(urlQueryRemover, '');
        }

        return text;
    }

    String normalizeLink(String text) {
        if (text.startsWith('//')) {
            text = 'https:' + text;
        }

        return text;
    }

    String normalizeMime(String text) => text;
}
