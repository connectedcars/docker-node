#!/bin/bash

# gpg keys listed at https://github.com/nodejs/node#release-team
NODE_KEYS="4ED778F539E3634C779C87C6D7062848A1AB005C
    141F07595B7B3FFE74309A937405533BE57C7D57
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5
    74F12602B6F1C4E913FAA37AD3A89613643B6201
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1
    61FC681DFB92A079F1685E77973F295594EC4689
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D
    A48C2BEE680E841632CD4E44F07496B3EB3C1762
    108F52B48DB57BB0CC439B2997B01419BD92F80A
    B9E2F5981AA6E0CD28160D9FF13993A75599653C"



YARN_KEYS="6A010C5166006599AA17F08146C2130DFD2497F5"

rm -f *.gpg

for key in $NODE_KEYS $YARN_KEYS; do
    gpg -q --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg -q --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" || \
    gpg -q --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key"
    gpg --batch --yes --armor --output $key.gpg --export $key
done
