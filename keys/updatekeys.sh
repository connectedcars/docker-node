#/bin/bash

# gpg keys listed at https://github.com/nodejs/node#release-team
NODE_KEYS="94AE36675C464D64BAFA68DD7434390BDBE9B9C5
    B9AE9905FFD7803F25714661B63B535A4C206CA9
    77984A986EBC2AA786BC0F66B01FBB92821C587A
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1
    FD3A5288F042B6850C66B31F09FE44734EB7990E
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D"

YARN_KEYS="6A010C5166006599AA17F08146C2130DFD2497F5"

rm -f *.gpg

for key in $NODE_KEYS $YARN_KEYS; do
    gpg -q --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg -q --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg -q --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key"
    gpg --batch --yes --armor --output $key.gpg --export $key
done