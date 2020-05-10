import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import '../errors.dart';

Future<Map<String, dynamic>> internalError(
    HttpRequest request,
    Db mongo,
    dynamic error,
) async {
    final type = 'INTERNAL_ERROR';
    final code = ERROR_CODES[type] ?? 0;
    final reason = ERROR_REASONS[type] ?? 'Internal error';

    print('Internal server error: $error');

    return {
        'error': {
            'code': code,
            'reason': reason,
        }
    };
}
