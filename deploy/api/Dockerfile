FROM node:13.12.0

WORKDIR /assistant

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY image/package.json .
COPY image/package-lock.json .

ENV NODE_ENV=production

RUN npm ci --dev

COPY image/src src
COPY image/tsconfig.json .

RUN npm run build
RUN npm run uglify
RUN cp dst/assistant.json dst.uglified/assistant.json
RUN rm -rf src dst .cache tsconfig.json node_modules
RUN mv dst.uglified dst
RUN npm ci --only=production

CMD npm start
