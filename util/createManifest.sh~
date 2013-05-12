#!/bin/bash
function printManifest {
    [ -f "manifest.version" ] || echo 1 > "manifest.version"
    read -r version < "manifest.version"
    ((version++))
    echo $version > "manifest.version"
    echo CACHE MANIFEST 
    echo " "
    echo "# Version $version" 
    echo NETWORK:
    echo "*"
    echo CACHE:
    cd static
    find  | egrep "\.(js|html|css|swf)$"
    find  | egrep "site-image/.*$"
    find  | egrep "font/.*$"
}
printManifest > static/manifest.appcache
exit 0
