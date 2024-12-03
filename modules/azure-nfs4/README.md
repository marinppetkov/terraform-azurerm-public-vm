Creating storage account with file share and private endpoint for internal connection<br>
Microsoft [Docs](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-quick-create-use-linux)
Once done the nfs share should be mounted. Example script below:<br>
```bash
sudo apt-get -y update
sudo apt-get install nfs-common
sudo mkdir -p /mount/fileshare8422/nfsdata
sudo mount -t nfs fileshare8422.file.core.windows.net:/fileshare8422/nfsdata /mount/fileshare8422/nfsdata -o vers=4,minorversion=1,sec=sys,nconnect=4
```

