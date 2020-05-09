import 'dart:io';

import '../errors.dart';

Future<Map<String, dynamic>> routeNotFound(
    HttpRequest request,
    HttpResponse response,
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
