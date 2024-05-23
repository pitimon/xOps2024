#!/bin/bash
vmid=$1
bridge=$2
imagename=$3
storage=$4
qm create $vmid --core 2 --memory 2048 --name Cloud$vmid --net0 virtio,bridge=$2 --serial0 socket --agent enabled=1
qm importdisk $vmid $imagename $storage
qm set $vmid --scsihw virtio-scsi-pci --scsi0 $storage:vm-$vmid-disk-0
qm resize $vmid scsi0 +1G
qm set $vmid --ide2 $storage:cloudinit
qm set $vmid --boot c --bootdisk scsi0
qm set $VMID --ipconfig0 ip=dhcp
