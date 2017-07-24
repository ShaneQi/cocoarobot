SCRIPT=`readlink -f "$0"`
SCRIPTPATH=`dirname "$SCRIPT"`
PROJPATH=`dirname "$SCRIPTPATH"`
docker run \
-d \
--name cocoarobot \
-v $PROJPATH:/cocoarobot \
-v /home/shane/persistence/cocoarobot/:/db/ \
-w /cocoarobot \
swift:3.1.0 \
/bin/sh -c \
"\
apt-get update;\
apt-get install libsqlite3-dev -y;\
swift build;\
./.build/debug/cocoarobot;\
"
