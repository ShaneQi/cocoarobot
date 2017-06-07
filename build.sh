sudo docker run --rm -v `pwd`/:/cocoarobot swift:latest /bin/sh -c "apt-get update; apt-get install uuid-dev libsqlite3-dev -y; cd cocoarobot; swift build;"
