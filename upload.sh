#!/bin/zsh

echo "upload files to prod vds ..."
    rsync -rv upload/home leetnews@marsgpl:/ || exit 1
echo "OK"
