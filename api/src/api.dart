import 'dart:convert';
import 'dart:io';

import './errorHandlers/methodNotAllowedForRoute.dart';
import './errorHandlers/routeNotFound.dart';
import './errorHandlers/internalError.dart';

import './methods/manifest.dart';
import './methods/getPosts.dart';

Future<void> main() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 80);

    print('Listening on ${server.address.address}:${server.port}');

    await for (HttpRequest request in server) {
        final response = request.response;
        final method = request.method;
        final uri = request.uri;

        Map<String, dynamic> answer = {};

        try {
            if (uri.path == '/api/manifest') {
                answer = (method == 'GET') ?
                    await manifest(request, response) :
                    await methodNotAllowedForRoute(request, response);
            } else if (uri.path == '/api/getPosts') {
                answer = (method == 'GET') ?
                    await getPosts(request, response) :
                    await methodNotAllowedForRoute(request, response);
            } else {
                answer = await routeNotFound(request, response);
            }
        } catch (error) {
            answer = await internalError(request, response, error);
        }

        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

        response.write(json.encode(answer));

        await response.close();
    }
}
