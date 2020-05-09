FROM google/dart

WORKDIR /leetnews/api

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN pub global activate dartman

ADD ./image .
RUN pub get

CMD dartman src/api.dart
