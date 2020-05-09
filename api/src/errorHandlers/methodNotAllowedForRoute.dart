import 'dart:io';

import '../errors.dart';

Future<Map<String, dynamic>> methodNotAllowedForRoute(
    HttpRequest request,
    HttpResponse response,
) async {
    final type = 'METHOD_NOT_ALLOWED_FOR_ROUTE';
    final code = ERROR_CODES[type] ?? 0;
    final reason = (ERROR_REASONS[type] ?? '')
        .replaceAll('%method', request.method)
        .replaceAll('%route', request.uri.path);

    return {
        'error': {
            'code': code,
            'reason': reason,
        }
    };
}
