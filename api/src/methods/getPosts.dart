import 'dart:io';

import '../entities/Post.dart';

// /api/getPosts?subjects=politics,sports&lastId=XXX&limit=20&locale=ru
Future<Map<String, dynamic>> getPosts(
    HttpRequest request,
    HttpResponse response,
) async {
    List<Post> posts = [];

    posts.add(Post(
        pubDate: DateTime.parse('2020-05-09T00:03:47+0300'),
        title: 'Как во время войны в СССР героически боролись с разгулом преступности',
        text: 'В День Победы принято говорить о подвигах Красной армии, вспоминать героические обороны и решающие прорывы. При этом на второй план уходят подвиги, которые советские люди совершали в тылу. Героическую борьбу с преступностью вели милиционеры, оказавшись в меньшинстве против хорошо вооруженных бандитов.',
        author: 'Владимир Седов',
        category: 'Силовые структуры',
        imgUrl: 'https://icdn.lenta.ru/images/2020/05/08/17/20200508172553603/pic_05d587590d1570a4a03654966e18b181.jpg',
        imgMime: 'image/jpeg',
        lang: 'ru',
        origId: 'https://lenta.ru/articles/2020/05/09/police/',
        origLink: 'https://lenta.ru/articles/2020/05/09/police/',
    ));

    posts.add(Post(
        pubDate: DateTime.parse('2020-05-08T17:06:00+0300'),
        title: 'Российской экономике предстоит смириться с падением значимости угля',
        text: 'Экономический кризис, вызванный пандемией коронавируса, не приведет к торможению процесса мирового перехода на возобновляемые источники энергии (ВИЭ). Об этом сообщили недавно специалисты Всемирного банка. Даже падение цен на нефть, как считает эксперт, не вызовет снижения активности по наращиванию ВИЭ.',
        author: 'Константин Ляпунов',
        category: 'Экономика',
        imgUrl: 'https://icdn.lenta.ru/images/2020/04/28/12/20200428121920437/pic_385789eab59969e6262e6dc365c4c219.jpg',
        imgMime: 'image/jpeg',
        lang: 'ru',
        origId: 'https://lenta.ru/articles/2020/05/08/enrgy/',
        origLink: 'https://lenta.ru/articles/2020/05/08/enrgy/',
    ));

    posts.add(Post(
        pubDate: DateTime.parse('2020-05-09T00:01:00+0300'),
        title: 'Религиозные американцы отказались от унитазов и телефонов. Что заставляет их жить в прошлом?',
        text: 'Американское религиозное движение амишей насчитывает около 200 тысяч последователей. Эти люди живут обособленно, так или иначе отвергают современные технологии и употребляют в пищу плоды земли, на которой живут. «Лента.ру» рассказывает о том, как и зачем они воюют с современностью.',
        author: 'Михаил Карпов',
        category: 'Из жизни',
        imgUrl: 'https://icdn.lenta.ru/images/2020/05/08/20/20200508203148287/pic_f7bce420225e7316ba8cc5cfbe18d32a.jpg',
        imgMime: 'image/jpeg',
        lang: 'ru',
        origId: 'https://lenta.ru/articles/2020/05/09/amish/',
        origLink: 'https://lenta.ru/articles/2020/05/09/amish/',
    ));

    posts.sort((p1, p2) => p2.compareTo(p1));

    return {
        'posts': posts,
    };
}
