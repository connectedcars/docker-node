#/bin/bash

DEBIAN_KEYS="7638D0442B90D010 04EE7237B7D453EC"

rm -f *.gpg

for key in $DEBIAN_KEYS; do
    gpg -q --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg -q --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg -q --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key"
    gpg --batch --yes --armor --output $key.gpg --export $key
done
