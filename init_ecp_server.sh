ECP_CONFIG=/opt/demo/data-ecp-archive.json

ecpserver() {
rm -rf $BACKUP_FOLDER/IRIS.DAT
envsubst < ${ECP_CONFIG} > ${ECP_CONFIG}.resolved
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Set sc = ##class(Api.Config.Services.Loader).Load("${ECP_CONFIG}.resolved")
Hang 2
Do { w !,"accept pending ecp app server list" s i=\$i(i),rset = ##class(%ResultSet).%New("SYS.ECP:SSLPendingConnections") d rset.Execute(),rset.Next() s cn = rset.Get("SSLComputerName") w " Accept cn ",cn d:cn'="" ##class(SYS.ECP).RemoveFromPendingList(cn,1) d rset.%Close() hang 5 } while (i<20)
Halt
END
}

ecpserver

exit 0