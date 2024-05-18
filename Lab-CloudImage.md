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
- Group 250
```
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && 

sudo dpkg -i cloudflared.deb && 

sudo cloudflared service install eyJhIjoiNWZkZjAwYmY5OGUxNGJiYTJkY2Q3NDhmMmYyODBjMWMiLCJ0IjoiYjU0YTQ4OTUtYmNkYS00MjE1LTgwNGItMDgxYWNhZDVhMDMyIiwicyI6Ill6VXlOV0UzTURVdFpURTBNeTAwWkdSbExUazRNekl0WlRobVpXTTBPV0UyT1RKaSJ9
```
- Group 251
```
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && 

sudo dpkg -i cloudflared.deb && 

sudo cloudflared service install eyJhIjoiNWZkZjAwYmY5OGUxNGJiYTJkY2Q3NDhmMmYyODBjMWMiLCJ0IjoiZjFkYjlhODktNmQyZi00ZGU4LWFmODAtOGUzNjE3ZjI2NjQ2IiwicyI6IlpXSmlOV1EzTVRRdFl6azNNUzAwTTJNMUxXRmpPRFV0TVdRNVpESmlaRE5sWTJReiJ9
```
- Group 252
```
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && 

sudo dpkg -i cloudflared.deb && 

sudo cloudflared service install eyJhIjoiNWZkZjAwYmY5OGUxNGJiYTJkY2Q3NDhmMmYyODBjMWMiLCJ0IjoiOTRmNmUzMWMtYzU4ZS00ZjMyLWIzN2ItODU3NTljMjExNGNkIiwicyI6IlpXUTRNV1JtWW1JdFpXWXpZaTAwTjJSaExUZ3pZMkl0TWpRMll6Y3daR05tTUdVNSJ9
```
