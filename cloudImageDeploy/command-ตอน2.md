## Re-again cloud image deploy (optimal resource)
```
./qmtemplate.sh 9000 vmbr0,tag=701 noble-server-20240521.img ceph_tiering
```
```
qm set 9000 --cipassword="12341234" --ciuser=test
qm set 9000 --sshkey ./mykey.pub

qm start 9000
qm terminal 9000

qm agent 9000 network-get-interfaces
```
>> ssh test@[vm_IPaddr]

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
>> re-login and docker non-root run
```
dosker ps
docker run hello-world
```

- Reset machine-id before create template
>> guest shell
```
sudo cp /dev/null /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo init 0
```
>> pve node shell
```
qm template 8000
qm clone 8000 888 --full true --name demo101
```
```
qm resize 888 scsi0 +8G
qm set 888 --cipassword="12121212" --ciuser=demo
qm set 888 --sshkey ./mykey.pub
qm start 888
qm agent 888 network-get-interfaces
```

