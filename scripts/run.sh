docker run \
-d \
--name cocoarobot \
-v `pwd`/:/cocoarobot \
-v /home/shane/persistence/cocoarobot/:/db/ \
-w /cocoarobot \
swift:3.1.0 \
/bin/sh -c \
"\
apt-get update;\
apt-get install uuid-dev libsqlite3-dev -y;\
swift build;\
./.build/debug/cocoarobot;\
"
