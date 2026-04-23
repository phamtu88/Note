#!/bin/bash
# ==============================================================================
# SCRIPT 1a: CẤU HÌNH HỆ ĐIỀU HÀNH - TRƯỜNG HỢP ONLINE (CÓ INTERNET)
# Áp dụng: Khi máy chủ có kết nối Internet để tải gói Pre-install từ Oracle.
# Thực thi: Chạy bằng quyền ROOT.
# ==============================================================================

# 1. Tắt Firewall, SELinux và cấu hình Hosts
echo ">>> Stopping Firewall, SELinux and configuring Hosts..."
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo "192.168.1.100   oracle19.localdomain   oracle19" >> /etc/hosts

# 2. Cài đặt gói Pre-install (Tự động tạo user, dba groups, kernel params)
echo ">>> Installing Oracle Pre-install RPM from Internet..."
yum install -y oracle-database-preinstall-19c

# 3. Đặt mật khẩu mặc định cho user oracle
echo ">>> Setting password 'oracle' for user oracle..."
echo "oracle" | passwd --stdin oracle

echo "DONE: OS Online setup completed successfully."
