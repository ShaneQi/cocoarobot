#!/bin/bash
docker run \
-it \
--rm \
--name cocoarobot_build \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
shaneqi/cocoarobot:latest \
/bin/bash -c \
"swift build"
