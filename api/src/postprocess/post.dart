import '../entities/Post.dart';

Post postprocessPost(Post post) {
    final mime = post.imgMime;

    if (
        mime != 'image/jpg' &&
        mime != 'image/jpeg' &&
        mime != 'image/pjpeg' &&
        mime != 'image/png' &&
        mime != 'image/webp'
    ) {
        post.imgUrl = '';
    }

    return post;
}
