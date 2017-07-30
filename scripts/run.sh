SCRIPT=`readlink -f "$0"`
SCRIPTPATH=`dirname "$SCRIPT"`
PROJPATH=`dirname "$SCRIPTPATH"`
docker run \
-d \
--name cocoarobot \
--link mysql:mysql \
-v $PROJPATH:/cocoarobot \
-w /cocoarobot \
swift:3.1.0 \
/bin/bash -c \
"\
apt update && apt install libsqlite3-dev -y;\
swift build && ./.build/debug/cocoarobot;\
"
