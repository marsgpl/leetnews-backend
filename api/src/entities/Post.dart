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
        this.origName = '',
        this.isCovid = false,
    }) :
        id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        pubDate = pubDate ?? DateTime.now();

    final String id;
    final DateTime createdAt;
    DateTime pubDate;
    String title;
    String text;
    String author;
    String category;
    String imgUrl;
    String imgMime;
    String lang;
    String origId;
    String origLink;
    String origName;
    bool isCovid;

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

    Post.fromMongo(Map<String, dynamic> mongoData) :
        id = mongoData['_id'].toHexString() ?? Uuid().v4(),
        createdAt = mongoData['createdAt'] ?? DateTime.now(),
        pubDate = mongoData['pubDate'] ?? DateTime.now(),
        title = mongoData['title'] ?? '',
        text = mongoData['text'] ?? '',
        author = mongoData['author'] ?? '',
        category = mongoData['category'] ?? '',
        imgUrl = mongoData['imgUrl'] ?? '',
        imgMime = mongoData['imgMime'] ?? '',
        lang = mongoData['lang'] ?? '',
        origId = mongoData['origId'] ?? '',
        origLink = mongoData['origLink'] ?? '',
        origName = mongoData['origName'] ?? '',
        isCovid = mongoData['isCovid'] ?? false;

    Map<String, dynamic> toJson() => {
        'id': id,
        // createdAt
        'pubDate': pubDate.toString(),
        'title': title,
        'text': text,
        // author
        'category': category,
        'imgUrl': imgUrl,
        // imgMime
        'lang': lang,
        // origId
        'origLink': origLink,
        'origName': origName,
        // isCovid
    };
}
