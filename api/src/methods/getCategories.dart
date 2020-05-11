import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import '../entities/Category.dart';

Future<Map<String, dynamic>> getCategories(
    HttpRequest request,
    Db mongo,
) async {
    final postsColl = mongo.collection('posts');
    final distinct = await postsColl.distinct('category');

    List<Category> categories = [];

    for (String title in distinct.values.first) {
        if (title.length == 0) continue;

        categories.add(Category(
            id: title,
            title: title,
        ));
    }

    return {
        'categories': categories,
    };
}
