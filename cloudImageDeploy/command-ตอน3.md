# export vm image from ceph
## step-guide
- download cloud image (Debian 12)
- image customize
- vm create by qm command
- vm install docker-engine
- clear machine-id
- ceph export vm
- convert image
## step command
```
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

virt-customize -a debian-12-generic-amd64.qcow2 --install qemu-guest-agent,chrony,btop
virt-customize -a debian-12-generic-amd64.qcow2 --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' --timezone Asia/Bangkok
```
```
./qmtemplate.sh 2000 vmbr1 debian-12-generic-amd64.qcow2 era_pve
```
```
qm set 2000 --cipassword="12341234" --ciuser=test
qm set 2000 --sshkey ./mykey.pub
```
```
qm set 2000 --ipconfig0 ip=172.31.1.220/22,gw=172.31.1.254
qm set 2000 --nameserver="203.159.77.77 9.9.9.11"
```
```
qm set 2000 --ipconfig0 ip=dhcp
```
```
qm list
qm start 2000
qm terminal 2000
qm agent 2000 network-get-interfaces
```
[Docker Engine]()
```
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER
```
```
curl -fsSL https://pkgs.netbird.io/install.sh | sudo sh
```

```
sudo cp /dev/null /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo init 0
```
- export vm image
```
pvesm list era_pve --vmid 2000
pvesm path era_pve:vm-2000-disk-0 
rbd -p era_pve-metadata export vm-2000-disk-0 /tmp/d12-0525.raw
qemu-img convert -f raw /tmp/d12-0525.raw -O qcow2 /tmp/d12-0525.qcow2
```
