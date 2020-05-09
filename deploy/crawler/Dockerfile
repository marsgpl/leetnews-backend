FROM google/dart

WORKDIR /leetnews/crawler

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD ./image .
RUN pub get

RUN dart2native --output=crawler src/crawler.dart
RUN rm -rf src

CMD ./crawler
