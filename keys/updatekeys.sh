#!/bin/bash

# gpg keys listed at https://github.com/nodejs/node?tab=readme-ov-file#release-keys
NODE_KEYS="C0D6248439F1D5604AAFFB4021D900FFDB233756
DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7
CC68F5A3106FF448322E48ED27F5E38D5B0A215F
8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4
C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C
108F52B48DB57BB0CC439B2997B01419BD92F80A
A363A499291CBBC940DD62E41F10027AF002F8B0"



YARN_KEYS="6A010C5166006599AA17F08146C2130DFD2497F5"

MYSQL_KEY="A8D3785C"

rm -f *.gpg

for key in $NODE_KEYS $YARN_KEYS $MYSQL_KEY; do
    gpg -q --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg -q --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" || \
    gpg -q --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key"
    gpg --batch --yes --armor --output $key.gpg --export $key
done
