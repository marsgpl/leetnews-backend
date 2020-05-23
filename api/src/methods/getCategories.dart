import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import '../entities/Category.dart';
import '../isAboutCovid.dart';

// banTags=covid,xxx
Future<Map<String, dynamic>> getCategories(
    HttpRequest request,
    Db mongo,
) async {
    final params = request.uri.queryParameters;

    final banTags = (params['banTags'] ?? '').trim();

    final posts = mongo.collection('posts');
    final records = await posts.distinct('category');

    List<Category> categories = [];

    for (String categoryTitle in records.values.first) {
        if (categoryTitle.length == 0) continue;
        if (banTags.contains('covid') && isAboutCovid(categoryTitle)) continue;

        categories.add(Category(
            id: categoryTitle,
            title: categoryTitle,
        ));
    }

    return {
        'categories': categories,
    };
}
