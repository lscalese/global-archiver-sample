#!/bin/bash

# Database used to test the mirror.
DATABASE=/usr/irissys/mgr/myappdata

# Directory contain myappdata backuped by the master to restore on other nodes and making mirror.
BACKUP_FOLDER=/opt/backup

# Mirror configuration file in json config-api format for the master node.
MASTER_CONFIG=/opt/demo/mirror-master.json

# Mirror configuration file in json config-api format for the backup node.
BACKUP_CONFIG=/opt/demo/mirror-backup.json

# The mirror name...
MIRROR_NAME=DEMO

# Mirror Member list.
MIRROR_MEMBERS=BACKUP

# Performed on the master.
# configure mirroring on the first node.
master() {
rm -rf $BACKUP_FOLDER/IRIS.DAT
envsubst < ${MASTER_CONFIG} > ${MASTER_CONFIG}.resolved
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Set sc = ##class(Api.Config.Services.Loader).Load("${MASTER_CONFIG}.resolved")
Set ^log.mirrorconfig(\$i(^log.mirrorconfig)) = \$SYSTEM.Status.GetOneErrorText(sc)
Job ##class(Api.Config.Services.SYS.MirrorMaster).AuthorizeNewMembers("${MIRROR_MEMBERS}","${MIRROR_NAME}",600)
Hang 2
Set sc = ##class(SYS.ECP).ServerAction("${ARCHIVE_SERVER:-ARCHIVE}",3,1)
ZN "USER"
zpm "install global-archiver"
Halt
END
}

# Performed by the master, make a backup of the database "myappdata" added to the mirror.
make_backup() {
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).DismountDatabase(\"${DATABASE}\")"
md5sum ${DATABASE}/IRIS.DAT
cp ${DATABASE}/IRIS.DAT ${BACKUP_FOLDER}/IRIS.TMP
mv ${BACKUP_FOLDER}/IRIS.TMP ${BACKUP_FOLDER}/IRIS.DAT
chmod 777 ${BACKUP_FOLDER}/IRIS.DAT
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).MountDatabase(\"${DATABASE}\")"
}

# Restore the mirrored database "myappdata".  This restore is performed on "backup" node.
restore_backup() {
sleep 5
while [ ! -f $BACKUP_FOLDER/IRIS.DAT ]; do sleep 1; done
sleep 2
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).DismountDatabase(\"${DATABASE}\")"
cp $BACKUP_FOLDER/IRIS.DAT $DATABASE/IRIS.DAT
md5sum $DATABASE/IRIS.DAT
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).MountDatabase(\"${DATABASE}\")"
}

# Configure the mirroring on the backup node
other_node() {
sleep 5
envsubst < $1 > $1.resolved
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Set sc = ##class(Api.Config.Services.Loader).Load("$1.resolved")
hang 2
Set sc = ##class(SYS.ECP).ServerAction("${ARCHIVE_SERVER:-ARCHIVE}",3,1)
ZN "USER"
zpm "install global-archiver"
Halt
END
}

if [ "$IRIS_MIRROR_ROLE" == "master" ]
then
  master
  make_backup
else
  restore_backup
  other_node $BACKUP_CONFIG
fi

exit 0