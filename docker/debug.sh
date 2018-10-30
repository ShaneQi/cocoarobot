#!/bin/bash
docker run \
-it \
--rm \
--name cocoarobot-debug \
--link mysql:mysql \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
shaneqi/cocoarobot:latest \
/bin/bash -c \
"swift run"
