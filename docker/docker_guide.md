# HƯỚNG DẪN DOCKER THỰC CHIẾN: VẬN HÀNH, CHẨN ĐOÁN & TỐI ƯU HỆ THỐNG

Tài liệu này tổng hợp toàn diện các kiến thức thực chiến về Docker dành cho kỹ sư vận hành và phát triển: từ vòng đời container, mã lỗi exit code, quy trình troubleshooting, storage/networking cho đến Docker Compose và best practices tối ưu hóa image trong môi trường Production.

---

## I. CÁC LỆNH DOCKER CỐT LÕI VÀ VÒNG ĐỜI CONTAINER

### 1. Quản lý vòng đời Container

```bash
# Chạy container ở chế độ nền (detached), tự động restart và map port
docker run -d --name my-web -p 8080:80 --restart unless-stopped nginx:alpine
```

#### 🔍 Phân tích chi tiết câu lệnh mẫu trên:

| Thành phần | Ý nghĩa chi tiết |
| :--- | :--- |
| **`docker run`** | Khởi tạo và chạy container (tự động tải image từ Registry nếu máy chưa có). |
| **`-d`** *(detach)* | Chạy ở chế độ nền (background), trả lại dấu nhắc lệnh cho terminal. |
| **`--name my-web`** | Đặt tên định danh cho container là `my-web` để dễ quản trị thay vì tên ngẫu nhiên. |
| **`-p 8080:80`** | Ánh xạ cổng `<Host>:<Container>`: Mở cổng `8080` trên máy host trỏ vào cổng `80` bên trong container Nginx. |
| **`--restart unless-stopped`** | Tự động khởi động lại container khi crash hoặc khi reboot OS, trừ khi bạn chủ động tắt bằng tay. |
| **`nginx:alpine`** | Tên `Image:Tag`. Sử dụng bản phân phối Alpine Linux siêu nhẹ (~20MB) giúp tối ưu hiệu năng. |

```bash

# Xem danh sách container đang chạy
docker ps

# Xem tất cả container (kể cả đã dừng/crash)
docker ps -a

# Truy cập vào terminal bên trong container đang chạy
docker exec -it my-web /bin/sh   # hoặc /bin/bash đối với image Debian/Ubuntu

# Tạm dừng / Dừng / Khởi động lại
docker stop my-web      # Gửi tín hiệu SIGTERM (chờ 10s), sau đó SIGKILL
docker kill my-web      # Gửi trực tiếp SIGKILL (dừng ngay lập tức)
docker start my-web
docker restart my-web

# Xóa container (cờ -f để ép xóa cả container đang chạy)
docker rm -f my-web
```

---

### 2. Quản lý Image

```bash
# Build image từ Dockerfile tại thư mục hiện tại
docker build -t my-app:v1.0.0 .

# Build không dùng cache (khi cần tải lại hoàn toàn dependency mới)
docker build --no-cache -t my-app:v1.0.0 .

# Xem danh sách image trên máy host
docker images

# Đổi tag image để chuẩn bị đẩy lên registry
docker tag my-app:v1.0.0 registry.example.com/team/my-app:v1.0.0
```

#### 🔍 Phân tích cấu trúc định danh Registry khi gán Tag:
`docker tag my-app:v1.0.0 registry.example.com/team/my-app:v1.0.0`

* **Bản chất:** Tạo bí danh (alias pointer) trỏ tới cùng một Image ID gốc, **không nhân đôi dung lượng ổ đĩa**.
* **Cấu trúc tên đích (`registry.example.com/team/my-app:v1.0.0`):**
  - `registry.example.com`: Địa chỉ máy chủ Registry (Harbor, Nexus, AWS ECR...). Bỏ qua sẽ mặc định là Docker Hub.
  - `team`: Namespace / Dự án sở hữu image.
  - `my-app`: Tên dịch vụ / repository.
  - `:v1.0.0`: Phiên bản (Tag).
* **Luồng triển khai chuẩn:** `docker build` ➔ `docker tag` (gắn địa chỉ đích) ➔ `docker push`.

#### 🔄 Sơ đồ phối hợp 2 chiều: ĐẨY LÊN (Push) và KÉO VỀ (Pull)

Cả chiều **Đẩy (Upload)** và chiều **Kéo (Download)** đều dùng chung định danh có địa chỉ kho:

```text
       [ MÁY CỦA BẠN (Lập trình viên) ]
                      │
                      │ 1. Viết code & build image trên máy
                      ▼
               [ my-app:v1.0.0 ]
                      │
                      │ 2. docker tag (dán thêm địa chỉ kho)
                      ▼
     [ registry.example.com/team/my-app:v1.0.0 ]
                      │
                      │ 3. docker push (ĐẨY LÊN KHO CHUNG)
                      ▼
        ===============================
        KHO CHUNG CỦA CÔNG TY (REGISTRY)
        (registry.example.com)
        ===============================
                      │
                      │ 4. docker pull (KÉO VỀ SERVER ĐỂ CHẠY)
                      ▼
         [ MÁY CHỦ PRODUCTION (SERVER) ]
                      │
                      │ 5. docker run (Chạy cho khách hàng dùng)
                      ▼
                  [ Web App ]
```

* **Lập trình viên:** Dùng lệnh `docker push` để **cất sản phẩm mới** lên kho.
* **Server Production:** Dùng lệnh `docker pull` để **lấy sản phẩm từ kho về** chạy.

```bash
# Kéo (pull) / Đẩy (push) image
docker pull redis:7-alpine
docker push registry.example.com/team/my-app:v1.0.0

# Xóa image không dùng
docker rmi my-app:v1.0.0
```

---

### 3. Theo dõi tài nguyên & Giám sát

```bash
# Xem log container theo thời gian thực (100 dòng gần nhất)
docker logs -f --tail 100 my-web

# Xem log kèm mốc thời gian (timestamp)
docker logs -tf my-web

# Giám sát mức tiêu thụ CPU, RAM, Network I/O thời gian thực của mọi container
docker stats

# Xem danh sách tiến trình (processes) đang chạy bên trong container
docker top my-web

# Xem chi tiết toàn bộ cấu hình JSON (IP, Mount, Env, State, Port...)
docker inspect my-web
```

---

### 4. Dọn dẹp tài nguyên rác (Garbage Collection)

Khi chạy lâu ngày, Docker tích lũy nhiều dangling layers, stopped containers và unused networks gây tràn ổ đĩa máy chủ:

```bash
# Dọn dẹp an toàn: xóa container đã dừng, network thừa, image không gắn tag
docker system prune

# Dọn dẹp triệt để (Production cẩn trọng): xóa toàn bộ image chưa dùng và volume mồ côi
docker system prune -a --volumes -f
```

---

## II. BẢNG TRẠNG THÁI CONTAINER TRONG THỰC TẾ

Khi chạy `docker ps -a`, cột `STATUS` phản ánh tình trạng hiện tại của container:

| Trạng thái | Ý nghĩa kỹ thuật | Nguyên nhân thực tế |
| :--- | :--- | :--- |
| **Created** | Container đã khởi tạo nhưng chưa từng chạy lệnh `start` | Do vừa chạy `docker create` hoặc quá trình `docker run` gặp lỗi chuẩn bị |
| **Up (Running)** | Container đang hoạt động bình thường | Tiến trình chính (PID 1) đang chạy ở chế độ foreground |
| **Up (Paused)** | Mọi tiến trình trong container bị đóng băng tạm thời | Quản trị viên chủ động chạy `docker pause <id>` |
| **Restarting (x)** | Container liên tục bị chết và Docker tự động restart lại | Ứng dụng bị crash lặp đi lặp lại (tương đương CrashLoopBackOff trong K8s) |
| **Exited (0)** | Container đã kết thúc công việc thành công | Thường là script chạy xong tác vụ (Job/Migration), hoặc tiến trình bị thoát do chạy nền |
| **Exited (code != 0)** | Container dừng do gặp lỗi | Crash ứng dụng, thiếu cấu hình, hết RAM, hoặc lỗi cú pháp |
| **Dead** | Container ở trạng thái hỏng hóc, không thể xóa bình thường | Lỗi kernel I/O, filesystem bị lock hoặc Docker Daemon mất quyền can thiệp |

---

### 💡 CHÍNH SÁCH TỰ ĐỘNG KHỞI ĐỘNG (`--restart`)

| Chính sách | Hành vi | Khuyến nghị sử dụng |
| :--- | :--- | :--- |
| `no` | Mặc định. Không bao giờ tự restart khi container dừng | Dùng cho tác vụ chạy 1 lần (CLI script, DB migration) |
| `always` | Luôn tự restart container bất kể exit code nào, kể cả khi Docker Daemon restart | Ít dùng vì sẽ tự chạy lại cả khi bạn chủ động `docker stop` trước đó |
| `unless-stopped` | Luôn tự restart trừ khi người quản trị chủ động chạy lệnh `docker stop` | **Chuẩn Production** cho Web Service, API, Database |
| `on-failure[:max]` | Chỉ restart nếu container thoát với `exit code != 0`. Có thể giới hạn số lần thử | Dùng cho worker cần cơ chế retry có kiểm soát |

---

## III. CÁC MÃ LỖI THỰC TẾ (EXIT CODES) VÀ NGUYÊN NHÂN

Khi container dừng, mã thoát (`Exit Code`) là thông tin đắt giá nhất để khoanh vùng sự cố:

### 1. `Exit Code 0` (Thoát bình thường nhưng ngoài ý muốn)
* **Hiện tượng:** Chạy `docker run -d my-app` nhưng container lập tức chuyển sang `Exited (0)`.
* **Nguyên nhân cốt lõi (Vấn đề PID 1):** Container Docker chỉ tồn tại chừng nào **tiến trình gốc (PID 1)** còn sống. Nếu lệnh `CMD` hoặc `ENTRYPOINT` kích hoạt một service chạy ở chế độ background (ví dụ `systemctl start nginx` hoặc `service nginx start`), process gốc thoát ngay lập tức và container kết thúc.
* **Cách khắc phục:** Luôn giữ tiến trình chạy ở chế độ **foreground**:
  ```dockerfile
  # SAI:
  CMD service nginx start
  # ĐÚNG:
  CMD ["nginx", "-g", "daemon off;"]
  ```

---

### 2. `Exit Code 137` (SIGKILL hoặc OOMKilled)
* **Ý nghĩa:** `128 + 9 (SIGKILL) = 137`. Tiến trình bị ép buộc dừng ngay lập tức.
* **2 Nguyên nhân chính:**
  1. **OOMKilled (Out Of Memory):** Kernel Linux phát hiện container vượt quá mức RAM cho phép (`--memory`) hoặc máy chủ cạn kiệt RAM vật lý nên `oom-killer` tiêu diệt container.
     * Kiểm tra: `docker inspect <container-id> --format '{{.State.OOMKilled}}'` (nếu trả về `true` chính là bị tràn RAM).
  2. **Bị dừng thủ công:** Quản trị viên chạy `docker kill` hoặc quá trình `docker stop` hết thời gian chờ 10 giây (grace period) chuyển sang ép dừng.

---

### 3. `Exit Code 1` (Lỗi ứng dụng nội bộ)
* **Nguyên nhân:** Lỗi code (Uncaught Exception, Syntax Error, NullPointer, panic trong Go).
* **Cách kiểm tra:** Đọc log ứng dụng:
  ```bash
  docker logs <container-id>
  ```

---

### 4. `Exit Code 126` & `127` (Lỗi quyền thực thi / Lỗi đường dẫn)
* **Exit 126 (`Command cannot be invoked`):** File script trong `ENTRYPOINT` thiếu quyền thực thi (`chmod +x entrypoint.sh`).
* **Exit 127 (`Command not found`):** Sai đường dẫn trong `CMD` hoặc binary/file không tồn tại trong image (ví dụ dùng base image `alpine` nhưng script gọi `bash` thay vì `sh`).

---

### 5. Lỗi `port is already allocated`
* **Hiện tượng:**
  ```text
  Bind for 0.0.0.0:80 failed: port is already allocated
  ```
* **Cách xử lý:** Tìm tiến trình đang chiếm port trên máy host và tắt hoặc đổi port container:
  ```bash
  # Linux:
  sudo ss -tulpn | grep :80
  # Hoặc:
  sudo lsof -i :80
  ```

---

## IV. QUY TRÌNH CHẨN ĐOÁN VÀ TROUBLESHOOTING DOCKER CHUẨN

```mermaid
flowchart TD
    A[Container bị lỗi / không phản hồi] --> B["1. Kiểm tra trạng thái: docker ps -a"]
    B --> C{Exit Code là gì?}
    C -->|Exit 0| D["Kiểm tra CMD/ENTRYPOINT có chạy foreground không"]
    C -->|Exit 137| E["docker inspect kiểm tra .State.OOMKilled"]
    C -->|Exit 1 / Khác| F["2. Đọc log: docker logs --tail 100"]
    E --> G[Tăng limit RAM hoặc sửa Memory Leak]
    F --> H["3. Debug tương tác: docker run -it --entrypoint sh image"]
    D --> H
```

### Các bước chẩn đoán tuần tự:

1. **Bước 1: Kiểm tra State và ExitCode:**
   ```bash
   docker inspect <container-name> --format 'Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}} | Error: {{.State.Error}}'
   ```

2. **Bước 2: Đọc Log gần nhất:**
   ```bash
   docker logs --tail 200 -t <container-name>
   ```

3. **Bước 3: Khởi động container tạm thời để debug:**
   Nếu container crash liên tục khiến bạn không thể dùng `docker exec`, hãy override `ENTRYPOINT` để nhảy vào bên trong khám phá filesystem:
   ```bash
   docker run --rm -it --entrypoint /bin/sh <image-name>
   ```

---

## V. QUẢN LÝ DỮ LIỆU: VOLUMES VS BIND MOUNTS VS TMPFS

Docker cung cấp 3 cơ chế lưu trữ dữ liệu chính:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CÁC CƠ CHẾ LƯU TRỮ DOCKER                       │
├────────────────────┬────────────────────┬──────────────────────────────┤
│   NAMED VOLUMES    │    BIND MOUNTS     │            TMPFS             │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Quản lý bởi Docker │ Trỏ vào thư mục    │ Lưu hoàn toàn trên RAM       │
│ (/var/lib/docker/  │ bất kỳ trên Host   │ (mất dữ liệu khi container   │
│  volumes/...)      │ (vd: /home/app...) │  dừng)                       │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Chuẩn Production   │ Chuẩn Development  │ Dành cho dữ liệu nhạy cảm    │
│ DB, Persistent Data│ Live-reload code   │ Token, Session tạm thời      │
└────────────────────┴────────────────────┴──────────────────────────────┘
```

### 1. Named Volumes (Khuyến nghị số 1 cho Production)
Docker tự quản lý đường dẫn vật lý và quyền hạn (I/O tối ưu trên Linux):
```bash
# Tạo volume
docker volume create db_data

# Gắn volume vào container
docker run -d --name postgres -v db_data:/var/lib/postgresql/data postgres:16-alpine

# Xem danh sách và kiểm tra đường dẫn thật
docker volume ls
docker volume inspect db_data
```

### 2. Bind Mounts (Thích hợp cho môi trường Dev)
Ánh xạ trực tiếp file/thư mục từ máy host vào container. Sửa code trên máy host sẽ thấy ngay trong container:
```bash
docker run -d --name dev-web -p 3000:3000 -v $(pwd)/src:/app/src node:20-alpine
```

### 3. Sao lưu (Backup) và Khôi phục (Restore) Named Volume

* **Sao lưu Volume ra file `.tar`:**
  ```bash
  docker run --rm -v db_data:/data -v $(pwd):/backup alpine tar czf /backup/db_data_backup.tar.gz -C /data .
  ```
* **Khôi phục Volume từ file `.tar`:**
  ```bash
  docker run --rm -v db_data:/data -v $(pwd):/backup alpine sh -c "tar xzf /backup/db_data_backup.tar.gz -C /data"
  ```

---

## VI. MẠNG TRONG DOCKER (DOCKER NETWORKING)

### 1. Bảng so sánh các Driver Network

| Network Driver | Đặc điểm | Trường hợp sử dụng |
| :--- | :--- | :--- |
| **Bridge (Mặc định)** | Tạo mạng ảo nội bộ (NAT) cô lập trên máy host. Cần map port `-p` để ra ngoài. | Ứng dụng web, microservice chạy độc lập trên 1 server |
| **Host** | Bỏ qua lớp NAT, dùng chung trực tiếp stack mạng với máy host. Tốc độ cao nhất, không cần `-p`. | Ứng dụng cần throughput cực lớn, agent giám sát mạng |
| **None** | Container hoàn toàn bị cô lập, không có card mạng nào ngoài `lo` (loopback). | Chạy các thuật toán mã hóa, batch job cách ly bảo mật |
| **Overlay** | Kết nối mạng giữa nhiều máy host Docker khác nhau. | Docker Swarm cluster |
| **Macvlan** | Gán cho container một địa chỉ MAC thật, xuất hiện như một thiết bị vật lý trong LAN. | Ứng dụng legacy cần địa chỉ IP tĩnh từ router mạng |

---

### 2. Cơ chế phân giải tên miền nội bộ (Internal DNS Resolution)

> [!IMPORTANT]
> **Điểm mấu chốt:** Mạng Bridge mặc định (`bridge`) **KHÔNG** hỗ trợ tự động phân giải DNS theo tên container. Để các container gọi nhau bằng tên (Service Discovery), bạn **BẮT BUỘC** phải tạo **User-defined Bridge Network**.

```bash
# 1. Tạo network tùy chỉnh
docker network create my-net

# 2. Chạy Database gắn vào my-net
docker run -d --name db-postgres --network my-net postgres:16-alpine

# 3. Chạy Backend cùng mạng my-net. 
# Backend có thể kết nối thẳng đến DB bằng hostname: "db-postgres"
docker run -d --name backend-api --network my-net -e DB_HOST=db-postgres my-api:latest
```

---

## VII. DOCKER COMPOSE: TRIỂN KHAI VÀ QUẢN LÝ MULTI-CONTAINER

Docker Compose giúp khai báo toàn bộ stack dịch vụ (Web, DB, Cache, Network, Volume) trong một file `compose.yaml` (hoặc `docker-compose.yml`).

### 1. File mẫu chuẩn Production kèm Healthcheck

```yaml
services:
  database:
    image: postgres:16-alpine
    container_name: production_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: app_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - internal_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d app_db"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: production_api
    restart: unless-stopped
    depends_on:
      database:
        condition: service_healthy # Chờ DB thực sự sẵn sàng nhận kết nối mới start API
    environment:
      DATABASE_URL: postgres://postgres:secret@database:5432/app_db
    ports:
      - "8080:8080"
    networks:
      - internal_net

volumes:
  db_data:
    driver: local

networks:
  internal_net:
    driver: bridge
```

### 2. Các lệnh Docker Compose thường dùng nhất

```bash
# Khởi động toàn bộ stack ở chế độ nền
docker compose up -d

# Dừng và xóa toàn bộ container, network được tạo
docker compose down

# Dừng và xóa kèm toàn bộ Volume (Cẩn trọng mất data DB)
docker compose down -v

# Xem log toàn bộ hệ thống hoặc 1 service cụ thể
docker compose logs -f
docker compose logs -f api

# Build lại image khi code thay đổi
docker compose build --no-cache
docker compose up -d --build

# Chạy một lệnh tức thời bên trong service (vd: chạy migration)
docker compose exec api npm run migrate
```

---

## VIII. TỐI ƯU HÓA DOCKERFILE & BẢO MẬT (PRODUCTION BEST PRACTICES)

### 1. Kỹ thuật Multi-Stage Build (Thu nhỏ kích thước Image)
Giúp loại bỏ toàn bộ compiler, source code thừa, SDK nặng nề, chỉ giữ lại duy nhất artifact runtime:

```dockerfile
# STAGE 1: Build source code
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .

# STAGE 2: Minimal Runtime (Giảm từ 800MB -> dưới 25MB)
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata

# Tạo user không đặc quyền (Non-root user)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
ENTRYPOINT ["./server"]
```

---

### 2. Tận dụng Layer Caching để tăng tốc độ Build
Docker cache theo từng dòng lệnh. Luôn copy file khai báo thư viện trước, cài đặt thư viện, rồi mới copy toàn bộ code:

```dockerfile
# ĐÚNG (Cache thư viện tốt):
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# SAI (Mỗi lần sửa 1 dòng code đều phải cài lại toàn bộ thư viện):
COPY . .
RUN npm ci
```

---

### 3. Nguyên tắc bảo mật bắt buộc
1. **Không bao giờ chạy với user root:** Luôn khai báo `USER <non-root-user>` ở cuối Dockerfile để ngăn chặn container breakout tấn công máy host.
2. **Sử dụng `.dockerignore`:** Luôn tạo file `.dockerignore` để loại trừ `.git`, `node_modules`, `.env`, build artifact, tránh làm phình to build context và lộ bí mật.
3. **Quét lỗ hổng bảo mật:** Sử dụng Docker Scout hoặc Trivy:
   ```bash
   docker scout cves <image-name>
   ```
4. **Cố định tag (Immutable tags):** Tránh dùng tag `:latest` trong production. Luôn dùng tag cụ thể như `:1.22.1-alpine` hoặc sha256 digest để đảm bảo tính tái lập.

---

## IX. PHÂN BIỆT HỆ SINH THÁI: DOCKERFILE VS DOCKER COMPOSE VS DOCKER SWARM

Dockerfile, Docker Compose, và Docker Swarm đại diện cho 3 cấp độ khác nhau trong hành trình triển khai container:

### 1. Phân định nhanh bản chất

* 📄 **Dockerfile (Cấp độ Image):** Bản thiết kế (Blueprint) dùng để đóng gói mã nguồn, cài đặt môi trường và sinh ra **duy nhất 1 Image**.
* 🐙 **Docker Compose (Cấp độ Multi-Container trên 1 Host):** Công cụ điều phối các container chạy cùng nhau (vd: Web + DB + Redis) trên **một máy chủ duy nhất** qua file cấu hình `compose.yaml`.
* 🐝 **Docker Swarm (Cấp độ Multi-Host Cluster):** Công cụ điều phối cụm máy chủ (Orchestration) tích hợp sẵn trong Docker, kết nối **nhiều server/VPS** thành một cụm để tự động cân bằng tải, scale và tự phục hồi khi có máy chủ sập.

---

### 2. Bảng so sánh chi tiết

| Tiêu chí | **Dockerfile** | **Docker Compose** | **Docker Swarm** |
| :--- | :--- | :--- | :--- |
| **Nhiệm vụ chính** | **Đóng gói (Build)** tạo ra Image | **Khởi chạy & Liên kết** các Container | **Quản lý cụm & Điều phối** trên nhiều máy chủ |
| **Phạm vi hạ tầng** | 1 Image đơn lẻ | **1 Máy chủ (Single-Host)** | **Nhiều máy chủ (Multi-Host Cluster)** |
| **Định dạng file** | `Dockerfile` | `compose.yaml` (hoặc `docker-compose.yml`) | Dùng chung `compose.yaml` (lệnh `docker stack deploy`) |
| **Lệnh thực thi chính**| `docker build` | `docker compose up / down` | `docker swarm init`, `docker stack deploy`, `docker service` |
| **Tính sẵn sàng cao (HA)** | Không có | Không (nếu máy chủ chết, toàn bộ app chết) | **Có** (tự chuyển Container sang node khác khi node sập) |
| **Cân bằng tải (Load Balancing)**| Không có | Cần cấu hình reverse proxy ngoài (Nginx) | Tự động cân bằng tải nội bộ qua Routing Mesh |
| **Môi trường phù hợp** | Mọi giai đoạn (Dev, CI/CD, Production) | **Local Dev**, Test, hoặc Server Prod đơn lẻ | **Production vừa và nhỏ** (giải pháp nhẹ nhàng thay thế K8s) |

---

### 3. Sơ đồ phối hợp thực tế

```text
┌─────────────────┐
│   Dockerfile    │  1. Đóng gói mã nguồn Backend thành image "my-api:v1.0"
└────────┬────────┘
         │ (docker build)
         ▼
┌─────────────────┐
│  Docker Compose │  2. Khi lập trình (Local Dev):
│ (compose.yaml)  │     Chạy "my-api" + "Postgres" + "Redis" trên laptop chỉ với 1 lệnh
└────────┬────────┘
         │ (Đẩy lên Production cụm 5 server)
         ▼
┌─────────────────┐
│  Docker Swarm   │  3. Khi lên hạ tầng cụm máy chủ (Production):
│  (Hoặc K8s)     │     Deploy stack lên cụm 5 nodes. Tự động scale 10 replicas
└─────────────────┘     và tự phục hồi nếu 1 server bị sập.
```

---

### 4. Quy tắc chọn công cụ
1. **Dùng Dockerfile:** Khi bạn muốn build image ứng dụng để lưu trữ trên Registry.
2. **Dùng Docker Compose:** Khi bạn code dưới máy cá nhân (Local) hoặc chạy hệ thống trên 1 server độc lập.
3. **Dùng Docker Swarm:** Khi bạn có 2 server trở lên và muốn tính năng High Availability / Zero-downtime rolling update nhưng không muốn gánh chi phí vận hành phức tạp của Kubernetes.
