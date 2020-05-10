import 'dart:io';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart';

import '../entities/Post.dart';

// categories=Спорт,Интернет+и+СМИ
// limit=20
// langs=ru,en
// beforePubDate=2020-05-07%2021:02:00.002Z
Future<Map<String, dynamic>> getPosts(
    HttpRequest request,
    Db mongo,
) async {
    final params = request.uri.queryParameters;

    final categories = (params['categories'] ?? '');
    final beforePubDate = (params['beforePubDate'] ?? '');
    final limit = max(1, min(40, int.parse(params['limit'] ?? '20')));
    final langs = (params['langs'] ?? 'ru');

    final postsColl = mongo.collection('posts');
    final selector = where;

    if (beforePubDate.length > 0) {
        selector.lt('pubDate', DateTime.parse(beforePubDate));
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
        .sortBy('pubDate', descending: true)
        .limit(limit);

    final List<Post> posts = await postsColl
        .find(selector)
        .map((row) => Post.fromMongo(row))
        .toList();

    return {
        'posts': posts,
    };
}
