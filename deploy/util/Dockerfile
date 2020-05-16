FROM google/dart

WORKDIR /leetnews/util

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD ./image .
RUN pub get

RUN dart2native --output=util src/util.dart
RUN rm -rf src

CMD ./util
