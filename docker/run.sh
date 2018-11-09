#!/bin/bash
docker run \
-d \
--restart unless-stopped \
--name cocoarobot \
--network GoldenArches \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
shaneqi/cocoarobot:latest \
/bin/bash -c \
"swift run"
