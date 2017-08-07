docker run \
-it \
--rm \
--name cocoarobot_build \
-v `pwd`:/cocoarobot \
-w /cocoarobot \
swift:3.1.0 \
/bin/bash -c \
"\
apt update && apt install libmysqlclient-dev -y;\
swift build;\
"
