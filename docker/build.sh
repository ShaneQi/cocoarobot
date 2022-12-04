#!/bin/bash
docker run \
-it \
--rm \
--name cocoarobot_build \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
swift:5.7 \
/bin/bash -c \
"swift build"
