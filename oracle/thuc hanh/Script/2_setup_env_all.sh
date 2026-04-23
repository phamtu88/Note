#!/bin/bash
# ==============================================================================
# SCRIPT 2: CẤU HÌNH THƯ MỤC VÀ BIẾN MÔI TRƯỜNG (DÙNG CHO CẢ ONLINE & OFFLINE)
# Áp dụng: Sau khi đã chạy xong cực xong Script 1a hoặc 1b.
# Thực thi: Chạy bằng quyền ROOT.
# ==============================================================================

# 1. Tạo cấu trúc thư mục chuẩn OFA (Home & Data)
echo ">>> Creating Directory Structure (/u01 and /u02)..."
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02

# 2. Thiết lập biến môi trường Bash Profile cho user oracle
echo ">>> Configuring .bash_profile for user oracle..."
# Lưu ý: Chúng ta dùng lệnh append (>>) để tránh ghi đè dữ liệu cũ
cat >> /home/oracle/.bash_profile <<EOF

# --- Oracle 19c Environment Configuration ---
export ORACLE_HOSTNAME=oracle19.localdomain
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19.0.0/dbhome_1
export ORACLE_SID=orcl
export PATH=\$ORACLE_HOME/bin:\$PATH
EOF

chown oracle:oinstall /home/oracle/.bash_profile

echo "DONE: Environment preparation completed."
echo "NEXT STEP: Log in as 'oracle', unzip the installer, and run ./runInstaller."
