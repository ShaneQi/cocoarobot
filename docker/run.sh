#!/bin/bash
docker run \
-d \
--restart unless-stopped \
--name cocoarobot \
--network GoldenArches \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
swift:5.7 \
/bin/bash -c \
"swift run"
