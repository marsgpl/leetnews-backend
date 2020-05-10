import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

Future<Map<String, dynamic>> getCategories(
    HttpRequest request,
    Db mongo,
) async {
    final List<Map<String, dynamic>> categories = [
        { 'id': 'Бывший СССР', 'title': 'Бывший СССР' },
        { 'id': 'Дом', 'title': 'Дом' },
        { 'id': 'Из жизни', 'title': 'Из жизни' },
        { 'id': 'Интернет и СМИ', 'title': 'Интернет и СМИ' },
        { 'id': 'Культура', 'title': 'Культура' },
        { 'id': 'Мир', 'title': 'Мир' },
        { 'id': 'Наука и техника', 'title': 'Наука и техника' },
        { 'id': 'Путешествия', 'title': 'Путешествия' },
        { 'id': 'Россия', 'title': 'Россия' },
        { 'id': 'Силовые структуры', 'title': 'Силовые структуры' },
        { 'id': 'Спорт', 'title': 'Спорт' },
        { 'id': 'Ценности', 'title': 'Ценности' },
        { 'id': 'Экономика', 'title': 'Экономика' },
    ];

    return {
        'categories': categories,
    };
}
