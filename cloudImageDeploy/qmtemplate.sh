#!/bin/bash

### HOW TO USE
### Pre-req:
### - run on a Proxmox 6 server
### - a dhcp server should be active on vmbr1

VMID=$1
bridge=$2
imagename=$3
storage=$4
qm create $VMID --core 2 --memory 2048 --name Cloud$VMID --net0 virtio,bridge=$2 --serial0 socket --agent enabled=1
qm disk import $VMID $imagename $storage
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $storage:vm-$VMID-disk-0
qm resize $VMID scsi0 +1G
qm set $VMID --ide2 $storage:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --ipconfig0 ip=dhcp