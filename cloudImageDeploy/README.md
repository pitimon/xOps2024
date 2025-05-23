# 🌥️ Cloud Image Deploy บน Proxmox VE

คู่มือการสร้างและ deploy cloud images บน Proxmox VE พร้อมการ customize สำหรับการใช้งานจริง

## 📋 สารบัญ
- [วิดีโอสอน](#วิดีโอสอน)
- [ข้อกำหนดเบื้องต้น](#ข้อกำหนดเบื้องต้น)
- [การใช้งานเบื้องต้น](#การใช้งานเบื้องต้น)
- [การสร้าง Custom Images](#การสร้าง-custom-images)
- [การสร้าง Template](#การสร้าง-template)
- [การติดตั้ง Docker](#การติดตั้ง-docker)
- [เทคนิคขั้นสูง](#เทคนิคขั้นสูง)
- [แหล่งข้อมูล Cloud Images](#แหล่งข้อมูล-cloud-images)

## 🎥 วิดีโอสอน

| ตอน | หัวข้อ | ลิงก์วิดีโอ | Command ประกอบ |
|-----|-------|-------------|----------------|
| 1 | การใช้งานเบื้องต้น | [ดูวิดีโอ](https://www.loom.com/share/84a3720bc5584835a2ba0ebb757d4692?sid=93c273af-4b29-43aa-b2da-5198e1a49bc4) | [Commands ตอน 1](#demo-command-ตอนที่-1) |
| 2 | การ Customize Images | [ดูวิดีโอ](https://www.loom.com/share/e889e2b41aa141c6ad61627cb63380de?sid=c301bf1b-53b1-4f17-99f3-79aeaf896a6f) | [Commands ตอน 2](https://github.com/pitimon/xOps2024/blob/main/cloudImageDeploy/command-ตอน2.md) |
| 3 | Advanced Customization | [ดูวิดีโอ](https://www.loom.com/share/ba174cc6ec4c455dab4385222b81eb35?sid=999b5b8d-f9f2-4cb6-86c3-618b7352a0c3) | [Commands ตอน 3](https://github.com/pitimon/xOps2024/blob/main/cloudImageDeploy/command-ตอน3.md) |

**🎯 Custom Debian Image:** [Debian 12 MySite Custom Image](http://rustdesk.ipv9.me/iso/debian-12-generic-amd64-mod-20240525.qcow2)

## 🔧 ข้อกำหนดเบื้องต้น

- Proxmox VE 7.0+
- เครื่องมือ `libguestfs-tools` สำหรับ customize images
- SSH key pair สำหรับการเข้าถึง VMs

### ติดตั้งเครื่องมือที่จำเป็น
```bash
apt update -y
apt install libguestfs-tools needrestart -y
```

## 🚀 การใช้งานเบื้องต้น

### 1. ดาว์นโหลด Cloud Image
```bash
# Ubuntu 24.04 LTS (Noble)
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Debian 12 (Bookworm) - แนะนำสำหรับ production
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

### 2. สร้าง VM Template ด้วย qmtemplate.sh

**📋 ข้อกำหนดเบื้องต้น:**
- รันบน Proxmox server
- มี DHCP server ทำงานบน bridge vmbr1
- มี storage pool (เช่น era_pve, local-lvm, ceph_tiering)

**📝 Script qmtemplate.sh:**
```bash
#!/bin/bash
### HOW TO USE
### Pre-req:
### - run on a Proxmox server
### - a dhcp server should be active on vmbr1
VMID=$1
bridge=$2
imagename=$3
storage=$4

# สร้าง VM พื้นฐานด้วย 2 cores, 2GB RAM
qm create $VMID --core 2 --memory 2048 --name Cloud$VMID --net0 virtio,bridge=$2 --serial0 socket --agent enabled=1

# Import cloud image เข้า storage
qm disk import $VMID $imagename $storage

# กำหนด disk และ hardware
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $storage:vm-$VMID-disk-0
qm resize $VMID scsi0 +1G  # เพิ่มขนาด disk 1GB
qm set $VMID --ide2 $storage:cloudinit  # กำหนด cloud-init drive

# ตั้งค่า boot options
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --ipconfig0 ip=dhcp  # ใช้ DHCP สำหรับ IP
```

**🚀 วิธีใช้งาน:**

#### แบบเบื้องต้น (Basic)
```bash
# รูปแบบ: ./qmtemplate.sh [VM_ID] [Bridge] [Image_File] [Storage]
./qmtemplate.sh 5000 vmbr1 noble-server-cloudimg-amd64.img era_pve
```

#### แบบเหมาะสมสำหรับ Production (Optimal Resource)
```bash
# ใช้ VLAN tagging และ Ceph storage
./qmtemplate.sh 9000 vmbr0,tag=701 noble-server-20240521.img ceph_tiering
```

**📊 ตารางอธิบาย Parameters:**
| Parameter | คำอธิบาย | ตัวอย่าง |
|-----------|----------|----------|
| `VM_ID` | หมายเลข VM (100-999999) | `5000`, `9000` |
| `Bridge` | Network bridge ที่ใช้ | `vmbr0`, `vmbr1`, `vmbr0,tag=701` |
| `Image_File` | ไฟล์ cloud image | `noble-server-cloudimg-amd64.img` |
| `Storage` | Storage pool ใน Proxmox | `era_pve`, `local-lvm`, `ceph_tiering` |

**💡 Network Bridge Options:**
- `vmbr1` - Bridge ธรรมดา
- `vmbr0,tag=701` - Bridge พร้อม VLAN tag 701

**⚙️ สิ่งที่ Script ทำ:**
1. **สร้าง VM** ด้วยการกำหนดค่า CPU, Memory, Network
2. **Import Image** นำ cloud image เข้าสู่ storage
3. **กำหนด Hardware** ตั้งค่า disk controller และ cloud-init
4. **ปรับขนาด Disk** เพิ่มพื้นที่ 1GB จากขนาดเดิม
5. **ตั้งค่า Network** ใช้ DHCP สำหรับรับ IP อัตโนมัติ

### 3. กำหนดค่าผู้ใช้และ Network

#### การตั้งค่าผู้ใช้และ SSH
```bash
# กำหนดรหัสผ่านและชื่อผู้ใช้
qm set 9000 --cipassword="12341234" --ciuser=test

# เพิ่ม SSH key สำหรับการเข้าถึงแบบปลอดภัย
qm set 9000 --sshkey ./mykey.pub
```

#### การตั้งค่า Network

**แบบ DHCP (อัตโนมัติ):**
```bash
qm set 9000 --ipconfig0 ip=dhcp
```

**แบบ Static IP:**
```bash
# กำหนด IP แบบ static พร้อม gateway
qm set 2000 --ipconfig0 ip=172.31.1.220/22,gw=172.31.1.254

# กำหนด DNS servers
qm set 2000 --nameserver="203.159.77.77 9.9.9.11"

# เปลี่ยนกลับเป็น DHCP (หากต้องการ)
qm set 2000 --ipconfig0 ip=dhcp
```

### 4. เริ่มใช้งาน VM

```bash
# เริ่ม VM
qm start 9000

# เข้าถึงผ่าน terminal
qm terminal 9000

# ตรวจสอบ network interfaces
qm agent 9000 network-get-interfaces

# เข้าถึงผ่าน SSH (หลังจากได้ IP แล้ว)
ssh test@[VM_IP_ADDRESS]
```

**หยุดและลบ VM (หากต้องการ):**
```bash
qm stop 9000
qm destroy 9000
```

## 🎨 การสร้าง Custom Images

### ขั้นตอนการ Customize

#### 1. เตรียม Base Image (Ubuntu)
```bash
# คัดลอกและเปลี่ยนชื่อ image
cp noble-server-cloudimg-amd64.img noble-server-20240521.img
```

#### 2. ติดตั้ง Software พื้นฐาน
```bash
# ติดตั้ง packages ที่จำเป็น
virt-customize -a noble-server-20240521.img --install qemu-guest-agent,chrony,btop
```

#### 3. กำหนดค่า System
```bash
# ตั้งค่า timezone และ time synchronization
virt-customize -a noble-server-20240521.img \
  --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' \
  --timezone Asia/Bangkok
```

#### 4. สร้าง VM จาก Custom Image
```bash
# สร้าง VM template
./qmtemplate.sh 8000 vmbr1 noble-server-20240521.img era_pve

# กำหนดค่าผู้ใช้
qm set 8000 --cipassword="12341234" --ciuser=test
qm set 8000 --sshkey ./mykey.pub

# ทดสอบ VM
qm start 8000
qm terminal 8000
```

#### 5. ทดสอบ Services
```bash
# ตรวจสอบ services ต่าง ๆ (รันใน VM)
systemctl status qemu-guest-agent
ip a
ping 1.1.1.1
date
chronyc sources
```

### ขั้นตอนการสร้าง Debian Template

#### 1. ดาว์นโหลดและ Customize Debian Image
```bash
# ดาว์นโหลด Debian 12 cloud image
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Customize image พร้อม packages พื้นฐาน
virt-customize -a debian-12-generic-amd64.qcow2 --install qemu-guest-agent,chrony,btop

# ตั้งค่า timezone และ time sync
virt-customize -a debian-12-generic-amd64.qcow2 \
  --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' \
  --timezone Asia/Bangkok
```

#### 2. สร้าง VM จาก Debian Image
```bash
# สร้าง VM template
./qmtemplate.sh 2000 vmbr1 debian-12-generic-amd64.qcow2 era_pve

# กำหนดค่าผู้ใช้และ SSH
qm set 2000 --cipassword="12341234" --ciuser=test
qm set 2000 --sshkey ./mykey.pub

# เริ่ม VM และทดสอบ
qm start 2000
qm terminal 2000
qm agent 2000 network-get-interfaces
```

## 📤 Export VM Image จาก Ceph

### ขั้นตอนการ Export และ Convert

#### 1. ตรวจสอบ VM บน Storage
```bash
# ดู list ของ VMs บน storage
pvesm list era_pve --vmid 2000

# ดู path ของ disk
pvesm path era_pve:vm-2000-disk-0
```

#### 2. Export จาก Ceph RBD
```bash
# Export disk image จาก Ceph
rbd -p era_pve-metadata export vm-2000-disk-0 /tmp/d12-0525.raw

# Convert จาก raw เป็น qcow2
qemu-img convert -f raw /tmp/d12-0525.raw -O qcow2 /tmp/d12-0525.qcow2
```

#### 3. ตรวจสอบและใช้งาน
```bash
# ตรวจสอบข้อมูล image
qemu-img info /tmp/d12-0525.qcow2

# อัพโหลดไปยัง web server หรือ storage อื่น
# หรือนำไปใช้สร้าง template ใหม่
```

### ขั้นตอนการ Customize

#### 1. เตรียม Base Image
```bash
# คัดลอกและเปลี่ยนชื่อ image
cp noble-server-cloudimg-amd64.img noble-server-20240521.img
```

#### 2. ติดตั้ง Software พื้นฐาน
```bash
# ติดตั้ง packages ที่จำเป็น
virt-customize -a noble-server-20240521.img --install qemu-guest-agent,chrony,btop
```

#### 3. กำหนดค่า System
```bash
# ตั้งค่า timezone และ time synchronization
virt-customize -a noble-server-20240521.img \
  --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' \
  --timezone Asia/Bangkok
```

#### 4. สร้าง VM จาก Custom Image
```bash
# สร้าง VM template
./qmtemplate.sh 8000 vmbr1 noble-server-20240521.img era_pve

# กำหนดค่าผู้ใช้
qm set 8000 --cipassword="12341234" --ciuser=test
qm set 8000 --sshkey ./mykey.pub
```

## 🐧 Debian Cloud Image Deployment

### การ Deploy แบบเต็มรูปแบบ (Complete Workflow)

#### ขั้นตอนที่ 1: ดาว์นโหลดและ Customize
```bash
# ดาว์นโหลด Debian 12 cloud image
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Customize image พร้อม packages พื้นฐาน
virt-customize -a debian-12-generic-amd64.qcow2 --install qemu-guest-agent,chrony,btop

# ตั้งค่า timezone และ time sync
virt-customize -a debian-12-generic-amd64.qcow2 \
  --append-line '/etc/chrony/chrony.conf:pool time.google.com iburst maxsources 4' \
  --timezone Asia/Bangkok
```

#### ขั้นตอนที่ 2: สร้าง VM
```bash
# สร้าง VM template
./qmtemplate.sh 2000 vmbr1 debian-12-generic-amd64.qcow2 era_pve

# กำหนดค่าผู้ใช้และ SSH
qm set 2000 --cipassword="12341234" --ciuser=test
qm set 2000 --sshkey ./mykey.pub
```

#### ขั้นตอนที่ 3: ตั้งค่า Network (ทางเลือก)
```bash
# แบบ Static IP
qm set 2000 --ipconfig0 ip=172.31.1.220/22,gw=172.31.1.254
qm set 2000 --nameserver="203.159.77.77 9.9.9.11"

# หรือเปลี่ยนกลับเป็น DHCP
qm set 2000 --ipconfig0 ip=dhcp
```

#### ขั้นตอนที่ 4: เริ่มใช้งาน
```bash
# เริ่ม VM และทดสอบ
qm list
qm start 2000
qm terminal 2000
qm agent 2000 network-get-interfaces
```

#### ขั้นตอนที่ 5: ติดตั้ง Docker และ NetBird
```bash
# SSH เข้า VM
ssh test@[VM_IP]

# ติดตั้ง Docker (ใช้คำสั่งสำหรับ Debian จากส่วนด้านบน)
# ...

# ติดตั้ง NetBird
curl -fsSL https://pkgs.netbird.io/install.sh | sudo sh
```

#### ขั้นตอนที่ 6: เตรียมสำหรับ Template
```bash
# Reset machine-id (รันใน VM)
sudo cp /dev/null /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo init 0
```

### 1. เตรียม VM สำหรับทำ Template

#### Reset Machine ID (รันใน VM)
```bash
# ล้าง machine ID เพื่อให้ clone ได้ถูกต้อง
sudo cp /dev/null /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# ปิด VM
sudo init 0
```

### 2. สร้าง Template (รันบน Proxmox host)
```bash
# แปลง VM เป็น template
qm template 8000
```

### 3. Clone VMs จาก Template
```bash
# Clone VM ใหม่จาก template
qm clone 8000 888 --full true --name demo101

# ปรับขนาด disk (เพิ่ม 8GB)
qm resize 888 scsi0 +8G

# กำหนดค่าผู้ใช้ใหม่
qm set 888 --cipassword="12121212" --ciuser=demo
qm set 888 --sshkey ./mykey.pub

# เริ่ม VM และตรวจสอบ
qm start 888
qm agent 888 network-get-interfaces
```

### 4. ตัวอย่างการ Clone หลาย VMs
```bash
# Clone VMs หลายตัวพร้อมกัน
qm clone 8000 889 --full true --name demo102
qm clone 8000 890 --full true --name demo103

# กำหนดค่าแต่ละ VM
for vmid in 889 890; do
    qm set $vmid --cipassword="12121212" --ciuser=demo
    qm set $vmid --sshkey ./mykey.pub
    qm resize $vmid scsi0 +8G
done
```

## 🐳 การติดตั้ง Docker Engine

### 1. ลบ Docker packages เก่า
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove $pkg; 
done
```

### 2. เพิ่ม Docker Repository

#### สำหรับ Ubuntu:
```bash
# เพิ่ม GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# เพิ่ม repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### สำหรับ Debian:
```bash
# เพิ่ม GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# เพิ่ม repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 3. ติดตั้ง Docker
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# เพิ่มผู้ใช้เข้า docker group
sudo usermod -aG docker $USER
```

### 4. ติดตั้ง NetBird (VPN Mesh Network)
```bash
# ติดตั้ง NetBird client
curl -fsSL https://pkgs.netbird.io/install.sh | sudo sh
```

### 5. กำหนดค่า Docker logging
```bash
sudo tee /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

### 6. ทดสอบ Docker
```bash
# ออกจากระบบและเข้าใหม่เพื่อใช้ docker group
# หรือรัน: newgrp docker

docker ps
docker run hello-world
```

## ⚙️ เทคนิคขั้นสูง

### Auto Updates (Unattended Upgrades)
```bash
# ติดตั้ง unattended-upgrades
sudo apt install unattended-upgrades apt-listchanges python3-gi powermgmt-base -y

# เปิดใช้งาน auto updates
sudo bash -c 'echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections'
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# ทดสอบ
sudo unattended-upgrade -d
```

### Script อัพเดทระบบ
```bash
# สร้าง script สำหรับอัพเดท
tee update.sh << EOF
#!/bin/bash
sudo DEBIAN_FRONTEND=noninteractive apt update && \
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y && \
sudo needrestart -b -r a && \
sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y
EOF

chmod +x update.sh
./update.sh
```

## 🔗 แหล่งข้อมูล Cloud Images

### Official Cloud Images
- **Ubuntu:** [cloud-images.ubuntu.com](https://cloud-images.ubuntu.com/)
- **Debian:** [cloud.debian.org/images/cloud](https://cloud.debian.org/images/cloud/)
- **Fedora:** [fedoraproject.org/cloud/download](https://fedoraproject.org/cloud/download)

### แนะนำ Images ที่ใช้บ่อย
```bash
# Ubuntu 24.04 LTS (Noble Numbat)
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Ubuntu 22.04 LTS (Jammy Jellyfish)
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Debian 12 (Bookworm)
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

## 🚨 การแก้ไขปัญหา

### ปัญหาที่พบบ่อย

**VM ไม่ได้ IP address**
- ตรวจสอบ qemu-guest-agent: `systemctl status qemu-guest-agent`
- ตรวจสอบ network bridge configuration

**SSH ไม่ได้**
- ตรวจสอบ SSH key ถูกต้อง
- ตรวจสอบ cloud-init logs: `sudo cat /var/log/cloud-init-output.log`

**Docker permission denied**
- ออกจากระบบและเข้าใหม่หลังเพิ่ม user เข้า docker group
- หรือรัน: `newgrp docker`

## 🔄 Workflow สำหรับ Production

### แผนผัง Production Workflow

```
📥 ดาว์นโหลด Cloud Image
    ↓
🎨 Customize ด้วย virt-customize
    ↓
🖥️ สร้าง VM ด้วย qmtemplate.sh
    ↓
⚙️ ติดตั้ง Docker + NetBird + Apps
    ↓
🧹 Reset machine-id
    ↓
📦 สร้าง Template
    ↓
👥 Clone VMs หลายตัว
    ↓
📤 Export เป็น Image (ทางเลือก)
```

### ตัวอย่าง Complete Workflow

```bash
# 1. เตรียม base image
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
virt-customize -a debian-12-generic-amd64.qcow2 --install qemu-guest-agent,chrony,btop

# 2. สร้าง master VM
./qmtemplate.sh 9000 vmbr0,tag=701 debian-12-generic-amd64.qcow2 ceph_tiering
qm set 9000 --cipassword="12341234" --ciuser=test --sshkey ./mykey.pub

# 3. ติดตั้ง software
qm start 9000
ssh test@$(qm agent 9000 network-get-interfaces | jq -r '.[0]."ip-addresses"[0]."ip-address"')

# 4. สร้าง template
# (หลังจากติดตั้งครบแล้ว reset machine-id)
qm template 9000

# 5. deploy production VMs
for i in {1..5}; do
    qm clone 9000 $(( 9000 + i )) --full true --name "prod-app-$i"
    qm resize $(( 9000 + i )) scsi0 +8G
    qm set $(( 9000 + i )) --cipassword="prod_password" --ciuser=produser
    qm start $(( 9000 + i ))
done
```

## 📝 หมายเหตุ

- ทุกครั้งที่สร้าง template ควรล้าง machine-id เพื่อป้องกันปัญหา duplicate
- ใช้ `qm agent` commands สำหรับการจัดการ VM ที่มี qemu-guest-agent
- กำหนด log rotation สำหรับ Docker เพื่อป้องกัน disk เต็ม
- แนะนำให้ใช้ SSH key แทนรหัสผ่านสำหรับความปลอดภัย
- ควร test VM อย่างละเอียดก่อนทำเป็น template
- สำหรับ production ควรใช้ VLAN tagging เพื่อแยก network
