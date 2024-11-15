#!/bin/bash
IFS=$'\n'
for scsi in $(lsscsi)
 do
   LUN=$(echo $scsi | cut -d" " -f1 | cut -d":" -f 4 | tr -d "]")
  if [[ $LUN == "10" || $LUN == "20" ]]
  then
	  dev=$(echo $scsi | awk '{print $7}')
    dev_fs=$(lsblk -f $dev -n | awk '{print $2}')
    echo $dev
    if [[ $dev_fs ]]
    then
     mkdir /datadisk${LUN}
     mount $dev /datadisk${LUN}
     else
       mkdir /datadisk${LUN}
       mkfs.ext4 $dev
       mount $dev /datadisk${LUN}
    fi
    printf '%s%s 0 0\n' '/dev/disk/by-uuid/' "$(findmnt -n -o UUID,TARGET,FSTYPE,OPTIONS /datadisk${LUN})" >> /etc/fstab
  fi   
done
