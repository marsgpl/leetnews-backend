import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import '../entities/Category.dart';

Future<Map<String, dynamic>> getCategories(
    HttpRequest request,
    Db mongo,
) async {
    final posts = mongo.collection('posts');
    final records = await posts.distinct('category');

    List<Category> categories = [];

    for (String categoryTitle in records.values.first) {
        if (categoryTitle.length == 0) continue;

        categories.add(Category(
            id: categoryTitle,
            title: categoryTitle,
        ));
    }

    return {
        'categories': categories,
    };
}
