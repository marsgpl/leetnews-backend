import 'dart:io';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart';

import '../entities/Post.dart';

// categories=Спорт,Интернет+и+СМИ
// limit=20
// langs=ru,en
// lastId=2020-05-07%2021:02:00.002Z
// text=Коронавирус
Future<Map<String, dynamic>> searchPosts(
    HttpRequest request,
    Db mongo,
) async {
    final params = request.uri.queryParameters;

    final categories = (params['categories'] ?? '');
    final lastId = (params['lastId'] ?? '');
    final limit = max(1, min(40, int.parse(params['limit'] ?? '20')));
    final langs = (params['langs'] ?? 'ru');
    final text = (params['text'] ?? '').trim();

    if (text.length == 0) {
        return {
            'posts': [],
            'lastId': '',
        };
    }

    final posts = mongo.collection('posts');

    final selector = where
        .eq('\$text', {
            '\$search': text,
            '\$caseSensitive': false,
        })
        .metaTextScore('score');

    if (lastId.length > 0) {
        selector.lt('pubDate', DateTime.parse(lastId));
    }

    if (langs.contains(',')) {
        selector.oneFrom('lang', langs.split(','));
    } else {
        selector.eq('lang', langs);
    }

    if (categories.length > 0) {
        if (categories.contains(',')) {
            selector.oneFrom('category', categories.split(','));
        } else {
            selector.eq('category', categories);
        }
    }

    selector
        .sortByMetaTextScore('score')
        .sortBy('pubDate', descending: true)
        .limit(limit);

    final List<Post> postsList = await posts
        .find(selector)
        .map((row) => Post.fromMongo(row))
        .toList();

    String nextLastId = postsList.length == 0 ? '' :
        postsList[postsList.length - 1].pubDate.toString();

    return {
        'posts': postsList,
        'lastId': nextLastId,
    };
}
