import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import './errorHandlers/methodNotAllowedForRoute.dart';
import './errorHandlers/routeNotFound.dart';
import './errorHandlers/internalError.dart';

import './methods/manifest.dart';
import './methods/getPosts.dart';
import './methods/getCategories.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/admin';
const MONGO_DB = 'news';

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    mongo.databaseName = MONGO_DB;

    print('Mongo ready');

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
                    await manifest(request, mongo) :
                    await methodNotAllowedForRoute(request, mongo);
            } else if (uri.path == '/api/getPosts') {
                answer = (method == 'GET') ?
                    await getPosts(request, mongo) :
                    await methodNotAllowedForRoute(request, mongo);
            } else if (uri.path == '/api/getCategories') {
                answer = (method == 'GET') ?
                    await getCategories(request, mongo) :
                    await methodNotAllowedForRoute(request, mongo);
            } else {
                answer = await routeNotFound(request, mongo);
            }
        } catch (error) {
            answer = await internalError(request, mongo, error);
        }

        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

        response.write(json.encode(answer));

        await response.close();
    }
}
