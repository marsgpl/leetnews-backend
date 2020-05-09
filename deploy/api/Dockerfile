FROM google/dart

WORKDIR /leetnews/api

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD ./image .
RUN pub get

RUN dart2native --output=api src/api.dart
RUN rm -rf src

CMD ./api
