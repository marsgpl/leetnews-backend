import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

const MONGO_PATH = 'mongodb://root:nl7QkdoQiqIEnSse8IMgBUfEp7gOThr2@mongo:27017/news?authSource=admin&appName=util';

Future<void> main() async {
    Db mongo = Db(MONGO_PATH);
    await mongo.open();
    print('Mongo ready');

    await showIndexes(mongo);
    // await dedupOrigIds();

    exit(0);
}

Future<void> showIndexes(Db mongo) async {
    print('Indexes:');

    final posts = mongo.collection('posts');
    final indexes = await posts.getIndexes();

    for (final index in indexes) {
        print('    ${index['name']}:');

        for (final key in index.keys) {
            if (key == 'name') continue;

            print('        $key: ${index[key]}');
        }
    }
}
