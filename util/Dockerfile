FROM google/dart

WORKDIR /leetnews/util

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD pubspec.yaml .
ADD pubspec.lock .
ADD src .
RUN pub get

CMD dart src/util.dart
