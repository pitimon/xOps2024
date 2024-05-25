
# Cloud Image VDO clip
- [ตอน 1](https://www.loom.com/share/84a3720bc5584835a2ba0ebb757d4692?sid=93c273af-4b29-43aa-b2da-5198e1a49bc4)
- [ตอน 2](https://www.loom.com/share/e889e2b41aa141c6ad61627cb63380de?sid=c301bf1b-53b1-4f17-99f3-79aeaf896a6f)
  - [command](https://github.com/pitimon/xOps2024/blob/main/cloudImageDeploy/command-ตอน2.md)
- [ตอน 3](https://www.loom.com/share/ba174cc6ec4c455dab4385222b81eb35?sid=999b5b8d-f9f2-4cb6-86c3-618b7352a0c3)
  - [command](https://github.com/pitimon/xOps2024/blob/main/cloudImageDeploy/command-ตอน3.md)

### Original Cloud Image url
[Ubuntu Cloud Image](https://cloud-images.ubuntu.com/)
[Debian Cloud Image](https://cloud.debian.org/images/cloud/)
[Fedora Cloud Image](https://fedoraproject.org/cloud/download)

## Demo command ตอนที่ 1
```
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
./qmtemplate.sh 5000 vmbr1 noble-server-cloudimg-amd64.img era_pve
qm set 5000 --cipassword="12341234" --ciuser=test
qm start 5000
qm terminal 5000
qm agent 5000 network-get-interfaces
qm stop 5000
qm destroy 5000
```

## Custom Images
- [virt-customize](https://libguestfs.org/virt-customize.1.html)
>> packet request
```
apt update -y
apt install libguestfs-tools -y
```
>> prepare images
```
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
cp noble-server-cloudimg-amd64.img noble-server-20240521.img
virt-customize -a noble-server-20240521.img --install qemu-guest-agent,chrony,btop
virt-customize -a noble-server-20240521.img --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' --timezone Asia/Bangkok

```
- qm create
```
./qmtemplate.sh 8000 vmbr1 noble-server-20240521.img era_pve
```
```
qm set 8000 --cipassword="12341234" --ciuser=test
qm set 8000 --sshkey ./mykey.pub
```
```
qm list
qm start 8000
qm terminal 8000
qm agent 8000 network-get-interfaces
```
- create template
```
cp /dev/null /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
init 0

qm template 8000
qm clone 8000 888 --full true --name demo101
```
- check
```
systemctl status qemu-guest-agent
ip a
ping 1.1.1.1
dig
date
chronyc sources
```
[unattended-upgrades](https://wiki.debian.org/UnattendedUpgrades)
```
sudo apt install unattended-upgrades apt-listchanges -y
sudo apt install python3-gi powermgmt-base
sudo bash -c 'echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections'
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

sudo unattended-upgrade -d
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
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER
```
>> re-login
```
dosker ps
docker run hello-world
```
- create template
  >> On guest
```
cp /dev/null /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
init 0
```
  >> On pve node
```
qm template 8000
qm clone 8000 888 --full true --name demo101
qm clone 8000 889 --full true --name demo102
```