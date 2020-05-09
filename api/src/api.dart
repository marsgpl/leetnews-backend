import 'dart:convert';
import 'dart:io';

import './manifest.dart';

Future<void> main() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 80);

    print('Listening on ${server.address.address}:${server.port}');

    await for (HttpRequest request in server) {
        final response = request.response;

        response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

        response.write(json.encode({
            'manifest': manifest(),
        }));

        await response.close();
    }
}
