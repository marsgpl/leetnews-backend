import 'dart:io';

Future<Map<String, dynamic>> manifest(
    HttpRequest request,
    HttpResponse response,
) async => {
    'manifest': {
        'latestAppVersion': '1.0.0',
    },
};
