import 'dart:io';

import '../errors.dart';

Future<Map<String, dynamic>> internalError(
    HttpRequest request,
    HttpResponse response,
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
