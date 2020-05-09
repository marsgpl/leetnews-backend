FROM google/dart

WORKDIR /leetnews/api

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD ./image .
RUN pub get

CMD dart src/api.dart
