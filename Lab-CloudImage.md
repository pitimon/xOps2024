[Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- shell to proxmox node
```
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
wget http://rustdesk.ipv9.me/iso/jammy-server-cloudimg-amd64.img
```
```
qm create 8000 --core 2 --memory 2048 --name u2204CloudTemplate --net0 virtio,bridge=vmbr1 --serial0 socket --agent enabled=1
qm importdisk 8000 jammy-server-cloudimg-amd64.img ceph_replic
qm set 8000 --scsihw virtio-scsi-pci --scsi0 ceph_replic:vm-8000-disk-0
qm resize 8000 scsi0 +8G
qm set 8000 --ide2 ceph_replic:cloudinit
qm set 8000 --boot c --bootdisk scsi0
```
- clone Template

```
qm clone 8000 521 --full true --name vm521

```

- multi vm clone from template
```
n=500;for i in {1..20};do vmname=$(($n + $i)) ; echo qm clone 8000 $vmname --full true --name vm$vmname;done
```

- vm destroy
```
qm destroy [vmid]
```

- IPv4 forward
```
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```
```
tailscale down
tailscale up --advertise-routes=10.85.1.0/24,10.80.1.0/24 --reset 
```




