#!/bin/bash
docker run \
-d \
--name cocoarobot \
--link mysql:mysql \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
shaneqi/cocoarobot:latest \
/bin/bash -c \
"swift run"
