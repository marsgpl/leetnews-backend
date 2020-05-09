import 'package:uuid/uuid.dart';

class Post implements Comparable<Post> {
    Post({
        id,
        createdAt,
        pubDate,
        this.title = '',
        this.text = '',
        this.author = '',
        this.category = '',
        this.imgUrl = '',
        this.imgMime = '',
        this.lang = '',
        this.origId = '',
        this.origLink = '',
    }) :
        id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        pubDate = pubDate ?? DateTime.now();

    final String id;
    final DateTime createdAt;
    final DateTime pubDate;
    String title;
    String text;
    String author;
    String category;
    String imgUrl;
    String imgMime;
    String lang;
    String origId;
    String origLink;

    @override
    String toString() => '*Post(id: $id)';

    @override
    int compareTo(Post other) {
        int diff;

        diff = pubDate.compareTo(other.pubDate);
        if (diff != 0) return diff;

        diff = title.compareTo(other.title);
        if (diff != 0) return diff;

        return createdAt.compareTo(other.createdAt);
    }

    Map<String, dynamic> toMongo() => {
        '_id': id,
        'createdAt': createdAt,
        'pubDate': pubDate,
        'title': title,
        'text': text,
        'author': author,
        'category': category,
        'imgUrl': imgUrl,
        'imgMime': imgMime,
        'lang': lang,
        'origId': origId,
        'origLink': origLink,
    };
}
