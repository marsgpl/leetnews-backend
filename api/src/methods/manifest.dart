import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

Future<Map<String, dynamic>> manifest(
    HttpRequest request,
    Db mongo,
) async => {
    'manifest': {
        'latestAppVersion': '1.0.0',
    },
};
