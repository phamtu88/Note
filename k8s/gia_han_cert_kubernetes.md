# SOP: Gia hạn Certificate Kubernetes (kubeadm)

> **Tài liệu chuẩn hóa quy trình gia hạn cert cho cụm Kubernetes sử dụng kubeadm.**
> Cập nhật: 13/04/2026

---

## 1. Tổng quan

Kubernetes sử dụng **TLS certificate** để bảo mật giao tiếp giữa các thành phần (kube-apiserver, controller-manager, scheduler, etcd, kubelet...). Các cert do `kubeadm` tạo ra có **thời hạn mặc định 1 năm**. Nếu cert hết hạn, cụm K8s sẽ **ngừng hoạt động**.

### Các thành phần liên quan

| Thành phần | File cert/config |
|---|---|
| Admin user | `/etc/kubernetes/admin.conf` |
| API Server | `/etc/kubernetes/pki/apiserver.*` |
| API Server → etcd | `/etc/kubernetes/pki/apiserver-etcd-client.*` |
| API Server → kubelet | `/etc/kubernetes/pki/apiserver-kubelet-client.*` |
| Controller Manager | `/etc/kubernetes/controller-manager.conf` |
| Scheduler | `/etc/kubernetes/scheduler.conf` |
| Kubelet | `/etc/kubernetes/kubelet.conf` |
| etcd | `/etc/kubernetes/pki/etcd/*` |
| Front Proxy | `/etc/kubernetes/pki/front-proxy-client.*` |

---

## 2. Quy trình thực hiện

> **Lưu ý:** Thực hiện trên **từng Master node**. Nếu cụm có nhiều master, lặp lại quy trình cho mỗi node.

### Bước 1: Kiểm tra ngày hết hạn cert hiện tại

```bash
kubeadm certs check-expiration
```

**Output mẫu:**

```
CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Dec 28, 2023 06:54 UTC   79d             ca                      no
apiserver                  Dec 28, 2023 06:54 UTC   79d             ca                      no
apiserver-etcd-client      Dec 28, 2023 06:54 UTC   79d             etcd-ca                 no
apiserver-kubelet-client   Dec 28, 2023 06:54 UTC   79d             ca                      no
controller-manager.conf    Dec 28, 2023 06:54 UTC   79d             ca                      no
etcd-healthcheck-client    Dec 28, 2023 06:54 UTC   79d             etcd-ca                 no
etcd-peer                  Dec 28, 2023 06:54 UTC   79d             etcd-ca                 no
etcd-server                Dec 28, 2023 06:54 UTC   79d             etcd-ca                 no
front-proxy-client         Dec 28, 2023 06:54 UTC   79d             front-proxy-ca          no
scheduler.conf             Dec 28, 2023 06:54 UTC   79d             ca                      no
```

→ Cột **RESIDUAL TIME** cho biết số ngày còn lại trước khi cert hết hạn.

---

### Bước 2: Backup toàn bộ thư mục `/etc/kubernetes/`

```bash
mkdir -p /opt/kubernetes
cp -r /etc/kubernetes/* /opt/kubernetes/
```

**Kiểm tra backup:**

```bash
ls -la /opt/kubernetes/
```

> **Tại sao backup?**
> - Phòng trường hợp renew cert thất bại, có thể rollback bằng cách copy ngược lại.
> - Lệnh `cp -r` sẽ copy hết tất cả file và thư mục con (bao gồm `pki/`, `ssl/`, `manifests/`,...).

---

### Bước 3: Gia hạn tất cả cert

```bash
kubeadm certs renew all
```

**Output mong đợi:**

```
[renew] Reading configuration from the cluster...
certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate the apiserver uses to access etcd renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for liveness probes to healthcheck etcd renewed
certificate for etcd nodes to communicate with each other renewed
certificate for serving etcd renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler to use renewed
```

---

### Bước 4: Cập nhật kubeconfig cho user hiện tại

```bash
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

> **Tại sao cần bước này?**
> - File `$HOME/.kube/config` là bản copy của `admin.conf`.
> - Sau khi renew, cert trong `admin.conf` đã thay đổi nhưng `$HOME/.kube/config` vẫn chứa cert cũ.
> - Nếu bỏ qua bước này, lệnh `kubectl` sẽ báo lỗi xác thực.

---

### Bước 5: Restart các Pod control plane để áp dụng cert mới

```bash
kubectl -n kube-system delete pod -l 'component=kube-apiserver'
kubectl -n kube-system delete pod -l 'component=kube-controller-manager'
kubectl -n kube-system delete pod -l 'component=kube-scheduler'
kubectl -n kube-system delete pod -l 'component=etcd'
```

> **Giải thích:**
> - Các pod control plane là **static pod** do kubelet quản lý (không phải Deployment/ReplicaSet).
> - Khi delete pod, kubelet sẽ **tự động tạo lại pod mới** và load cert mới từ `/etc/kubernetes/pki/`.
> - Chỉ restart đúng 4 pod control plane, **KHÔNG ảnh hưởng** tới workload ứng dụng.

> **⚠️ KHÔNG nên dùng cách restart containerd/docker** vì sẽ restart **TẤT CẢ** container trên node, gây gián đoạn ứng dụng.

---

### Bước 6: Kiểm tra kết quả

**6.1. Kiểm tra tất cả pod đang running:**

```bash
kubectl get pods -A
```

→ Tất cả pod phải ở trạng thái `Running`. Các pod control plane sẽ có **AGE** rất nhỏ (vài giây/phút).

**6.2. Kiểm tra cert mới:**

```bash
kubeadm certs check-expiration
```

→ Cột **RESIDUAL TIME** phải hiển thị khoảng **364d** (gần 1 năm).

**6.3. Kiểm tra cluster health:**

```bash
kubectl get nodes
kubectl get cs
```

---

## 3. So sánh 2 phương pháp áp dụng cert mới

| | Delete Pod (✅ Khuyến nghị) | Restart Service (❌ Không khuyến nghị) |
|---|---|---|
| **Lệnh** | `kubectl delete pod -l component=...` | `systemctl restart containerd && systemctl restart kubelet` |
| **Phạm vi** | Chỉ 4 pod control plane | Toàn bộ container trên node |
| **Downtime** | Tối thiểu (~vài giây) | Lớn hơn — tất cả workload bị restart |
| **Ảnh hưởng ứng dụng** | ❌ Không | ✅ Có |
| **Độ an toàn** | Cao | Thấp |

---

## 4. Rollback khi gặp lỗi

Nếu sau khi renew cert mà cụm K8s không hoạt động, rollback bằng cách:

```bash
# Khôi phục toàn bộ từ backup
cp -r /opt/kubernetes/* /etc/kubernetes/

# Copy lại kubeconfig
cp /etc/kubernetes/admin.conf $HOME/.kube/config

# Restart kubelet
systemctl restart kubelet

# Kiểm tra
kubectl get nodes
```

---

## 5. Lưu ý quan trọng

1. **Certificate Authority (CA)** có thời hạn **10 năm**, KHÔNG cần renew thường xuyên.
2. Chỉ các cert do `kubeadm` quản lý (`EXTERNALLY MANAGED = no`) mới được renew bằng lệnh trên.
3. Nên đặt **lịch nhắc nhở trước 30 ngày** khi cert sắp hết hạn.
4. Nếu cụm có **nhiều Master node**, phải thực hiện quy trình trên **từng node**.
5. Nên thực hiện vào **khung giờ ít traffic** để giảm thiểu rủi ro.

---

## 6. Script tự động kiểm tra (Optional)

Có thể đặt cron job để cảnh báo khi cert còn ít hơn 30 ngày:

```bash
#!/bin/bash
# File: /opt/scripts/check_k8s_cert.sh

REMAINING=$(kubeadm certs check-expiration 2>/dev/null | grep -oP '\d+d' | sort -n | head -1 | grep -oP '\d+')

if [ -n "$REMAINING" ] && [ "$REMAINING" -lt 30 ]; then
    echo "⚠️ CẢNH BÁO: Kubernetes cert sẽ hết hạn trong ${REMAINING} ngày!" | \
    mail -s "[K8S ALERT] Cert sắp hết hạn" admin@company.com
fi
```

**Cron job (chạy mỗi ngày lúc 8h sáng):**

```bash
crontab -e
# Thêm dòng:
0 8 * * * /opt/scripts/check_k8s_cert.sh
```
