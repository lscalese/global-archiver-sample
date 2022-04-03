#!/bin/bash

# clean previous execution.
rm -vfr ./certificates ../certificates

mkdir -v ./certificates
chmod 777 ./certificates

docker run \
 --entrypoint /external/irisrun.sh \
 --name cert_generator \
 --volume $(pwd):/external \
 intersystemsdc/iris-community:latest \
 "/C=BE/ST=Wallonia/L=Namur/O=Community/OU=IT/CN=master" "master_server" \
 "/C=BE/ST=Wallonia/L=Namur/O=Community/OU=IT/CN=backup" "backup_server" \
 "/C=BE/ST=Wallonia/L=Namur/O=Community/OU=IT/CN=report" "archive_server"

docker container rm cert_generator

# change permissions

chown -v irisowner ./certificates/*_server.cer ./certificates/*_server.key
chgrp -v irisowner ./certificates/*_server.cer ./certificates/*_server.key
chmod -v 644 ./certificates/*_server.cer

# chmod for private key should be 600, but we have permissions denied with IRIS
# Maybe irisowner is not the good owner for these files. to analyse...
chmod -v 640 ./certificates/*.key
chgrp -v irisuser ./certificates/*_server.key

mv -v ./certificates ../certificates