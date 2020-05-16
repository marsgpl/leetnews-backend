#!/bin/zsh

SERVICE="$1"

cd deploy/$SERVICE || exit 1

DAY_HASH="$(date +"%Y-%m-%d")"
DART_HASH="$(sha256sum ../../$SERVICE/pubspec.lock | cut -d " " -f 1)"
IMAGE_TAG="docker.marsgpl.com/leetnews/$SERVICE:latest"

echo "clean previous build ..."
    rm -rf image || exit 1
echo "OK"

echo "prepare image files ..."
    mkdir image || exit 1
    cp -r ../../$SERVICE/src image || exit 1
    cp ../../$SERVICE/pubspec.yaml image || exit 1
    cp ../../$SERVICE/pubspec.lock image || exit 1
echo "OK"

echo "docker build ..."
    docker build \
        --tag=$IMAGE_TAG \
        --ulimit nofile=10240:10240 \
        . || exit 1
echo "OK"

echo "docker push ..."
    docker push $IMAGE_TAG || exit 1
echo "OK"

echo "cleanup ..."
    rm -rf image || exit 1
echo "OK"

echo "docker pull ..."
    ssh leetnews@marsgpl "docker pull $IMAGE_TAG" || exit 1
echo "OK"
