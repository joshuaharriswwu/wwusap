#!/bin/bash
 
## This script assumes the following data disk LUN layout
#LUN TYPE  MOUNTPOINT
# 0 - P6 (/hana/data #1)
# 1 - P6 (/hana/data #2)
# 2 - P6 (/hana/data #3)
# 3 - P6 (/hana/data #4)
# 4 - P10 (/hana/log #1)
# 5 - P10 (/hana/log #2)
# 6 - P10 (/hana/log #3)
# 7 - P20 (/hana/shared)
# 8 - P6 (/usr/sap)
 
# Ensure LVM is installed and up to date
sudo zypper install -y lvm2
 
# Pre-stage the mount directories
sudo mkdir -p /hana/data
sudo mkdir -p /hana/log
sudo mkdir -p /hana/shared
sudo mkdir -p /usr/sap
sudo chmod -R 0755 /hana
sudo chmod -R 0755 /usr/sap
 
# Creating the /hana/data volume
sudo pvcreate /dev/disk/azure/scsi1/lun[0123]
sudo vgcreate data-vg01 /dev/disk/azure/scsi1/lun[0123]
sudo lvcreate --extents 100%FREE --stripes 4 --stripesize 256 --name data-lv01 data-vg01
sudo mkfs.xfs /dev/data-vg01/data-lv01
 
# Update fstab
fs_uuid=$(blkid -o value -s UUID /dev/data-vg01/data-lv01)
echo "/dev/disk/by-uuid/$fs_uuid  /hana/data  xfs  defaults,barrier=0,nofail  0  2" | sudo tee -a /etc/fstab
 
# Creating the /hana/log volume
sudo pvcreate /dev/disk/azure/scsi1/lun[456]
sudo vgcreate log-vg01 /dev/disk/azure/scsi1/lun[456]
sudo lvcreate --extents 100%FREE --stripes 2 --stripesize 64 --name log-lv01 log-vg01
sudo mkfs.xfs /dev/log-vg01/log-lv01
 
# Update fstab
fs_uuid=$(blkid -o value -s UUID /dev/log-vg01/log-lv01)
echo "/dev/disk/by-uuid/$fs_uuid  /hana/log  xfs  defaults,barrier=0,nofail  0  2" | sudo tee -a /etc/fstab
 
# Creating the /hana/shared volume
sudo pvcreate /dev/disk/azure/scsi1/lun7
sudo vgcreate shared-vg01 /dev/disk/azure/scsi1/lun7
sudo lvcreate --extents 100%FREE --name shared-lv01 shared-vg01
sudo mkfs.xfs /dev/shared-vg01/shared-lv01
 
# Update fstab
fs_uuid=$(blkid -o value -s UUID /dev/shared-vg01/shared-lv01)
echo "/dev/disk/by-uuid/$fs_uuid /hana/shared  xfs  defaults,barrier=0,nofail  0  2" | sudo tee -a /etc/fstab
 
 
# Creating the /usr/sap volume
sudo pvcreate /dev/disk/azure/scsi1/lun8
sudo vgcreate usrsap-vg01 /dev/disk/azure/scsi1/lun8
sudo lvcreate --extents 100%FREE --name usrsap-lv01 usrsap-vg01
sudo mkfs.xfs /dev/usrsap-vg01/usrsap-lv01
 
# Update fstab
fs_uuid=$(blkid -o value -s UUID /dev/usrsap-vg01/usrsap-lv01)
echo "/dev/disk/by-uuid/$fs_uuid /usr/sap  xfs  defaults,barrier=0,nofail  0  2" | sudo tee -a /etc/fstab
 
# Mount the new filesystems
sudo mount -aupdated