#!/bin/bash
docker run \
-d \
--name cocoarobot \
--link mysql:mysql \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
cocoarobot:latest \
/bin/bash -c \
"\
swift build && ./.build/debug/cocoarobot;\
"
