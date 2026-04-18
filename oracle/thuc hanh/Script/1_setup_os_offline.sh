#!/bin/bash
# ==============================================================================
# SCRIPT 1b: CẤU HÌNH HỆ ĐIỀU HÀNH - TRƯỜNG HỢP OFFLINE (KHÔNG CÓ INTERNET)
# Áp dụng: Khi máy chủ KHÔNG có mạng, phải dùng đĩa ISO để cài thư viện.
# Yêu cầu: Đã Mount đĩa ISO của Oracle Linux vào /mnt trước khi chạy.
# Thực thi: Chạy bằng quyền ROOT.
# ==============================================================================

# 1. Tắt Firewall & SELinux
echo ">>> Stopping Firewall and SELinux..."
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 2. Cấu hình Local Repo (Trỏ vào /mnt)
echo ">>> Configuring Local Repository from ISO..."
cat > /etc/yum.repos.d/local.repo <<EOF
[LocalRepo]
name=Oracle Linux ISO
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF

# 3. Cài đặt các thư viện cần thiết
echo ">>> Installing dependencies from Local Repo..."
yum install -y --disablerepo="*" --enablerepo="LocalRepo" \
binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh \
libaio libaio-devel libstdc++ libstdc++-devel make sysstat

# 4. Tạo User & Group thủ công (Vì không có gói pre-install RPM)
echo ">>> Creating oracle user and groups..."
groupadd -g 54321 oinstall
groupadd -g 54322 dba
useradd -u 54321 -g oinstall -G dba oracle
echo "oracle" | passwd --stdin oracle

# 5. Cấu hình tham số nhân (Kernel Params)
echo ">>> Configuring Kernel Parameters..."
cat > /etc/sysctl.d/99-oracle.conf <<EOF
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmax = 4294967296
kernel.shmall = 2097152
kernel.shmmni = 4096
fs.aio-max-nr = 1048576
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF
sysctl --system

# 6. Cấu hình giới hạn tài nguyên (Limits)
echo ">>> Configuring resource limits..."
cat > /etc/security/limits.d/99-oracle.conf <<EOF
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
EOF

echo "DONE: OS Offline setup completed successfully."
