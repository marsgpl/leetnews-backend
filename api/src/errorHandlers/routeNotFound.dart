import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import '../errors.dart';

Future<Map<String, dynamic>> routeNotFound(
    HttpRequest request,
    Db mongo,
) async {
    final type = 'ROUTE_NOT_FOUND';
    final code = ERROR_CODES[type] ?? 0;
    final reason = (ERROR_REASONS[type] ?? '')
        .replaceAll('%route', request.uri.path);

    return {
        'error': {
            'code': code,
            'reason': reason,
        }
    };
}
