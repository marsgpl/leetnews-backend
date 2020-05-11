import 'package:uuid/uuid.dart';

class Category {
    Category({
        id,
        this.title = '',
    }) :
        id = id ?? Uuid().v4();

    final String id;
    String title;

    @override
    String toString() => '*Category(id: $id)';

    Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
    };
}
