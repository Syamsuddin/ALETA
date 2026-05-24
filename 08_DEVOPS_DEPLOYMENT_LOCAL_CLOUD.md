---
doc: "08"
title: "DevOps Deployment"
scope: "docker-compose 12 services dengan healthchecks, nginx multi-subdomain config, secrets pattern, backup schedule"
key_entities: [aleta_postgres, aleta_neo4j, aleta_ollama, aleta_keycloak, aleta_vector_db, nginx, docker-compose]
depends_on: ["07"]
loaded_by_tasks: [T-001, T-002, T-003, T-004, T-005]
---

# FILE: 08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md
# PROJECT ALETA: DEVOPS INFRASTRUCTURE & DOCKER COMPOSE SPECIFICATION

## 1. PENDAHULUAN & STRATEGI ORKESTRASI
Dokumen ini menetapkan spesifikasi penyiapan infrastruktur server (*Deployment*) untuk Project ALETA pada lingkup Yayasan. 

Untuk memastikan kemudahan pemeliharaan oleh tim IT internal Yayasan yang memiliki keterbatasan sumber daya manusia, seluruh arsitektur sistem ALETA dibungkus menggunakan teknologi kontainerisasi **Docker**. Penggunaan Docker Compose dinilai paling optimal untuk skala Yayasan karena tidak membutuhkan biaya operasional overhead yang tinggi jika dibandingkan dengan Kubernetes, namun tetap menjamin isolasi layanan yang andal.

---

## 2. ARSITEKTUR INFRASTRUKTUR SISTEM (TOPOLOGI JARINGAN)
Seluruh kontainer dihubungkan ke dalam satu jaringan internal terisolasi bernama `aleta_network`. Hanya kontainer `aleta_api_gateway` (Nginx) yang membuka port keluar ($80$/$443$) untuk menerima koneksi internet dari aplikasi *frontend* siswa, guru, dan orang tua.


```

```
              [ INTERNET / MOBILE & WEB APPS ]
                             │
                             ▼ (Port 80/443)
               ┌───────────────────────────┐
               │ aleta_api_gateway (Nginx) │
               └─────────────┬─────────────┘
                             │ (Internal Network)
                             ▼
  ┌──────────────────────────┴──────────────────────────┐
  │                                                     │
  ▼                                                     ▼

```

┌───────────────┐                                     ┌───────────────┐
│  aleta_core_  │ ──► [ Redis Sesi ]                  │ aleta_ai_     │
│ api (FastAPI) │ ──► [ PostgreSQL Relasional ]       │ engine (Py)   │
└───────────────┘ ──► [ Neo4j Graph Kurikulum ]       └───────┬───────┘
│
▼
[ Ollama LLM ]

```

---

## 3. BERKAS KONFIGURASI DOCKER COMPOSE UTAMA (`docker-compose.yml`)
Salin seluruh blok kode di bawah ini ke dalam berkas bernama `docker-compose.yml` pada direktori utama server Anda. Untuk production, semua secret wajib diambil dari `.env`, Docker secrets, atau secret manager. Nilai contoh di bawah tidak boleh dipakai sebagai credential production.

```yaml
version: '3.8'

networks:
  aleta_network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
  neo4j_data:
    driver: local
  redis_data:
    driver: local
  ollama_data:
    driver: local
  keycloak_data:
    driver: local
  vector_db_data:
    driver: local
  backups:
    driver: local

services:
  # 1. DATABASE RELASIONAL TERPUSAT (POSTGRESQL)
  aleta_postgres:
    image: postgres:15-alpine
    container_name: aleta_postgres
    restart: always
    environment:
      POSTGRES_USER: aleta_admin
      POSTGRES_PASSWORD: ${ALETA_POSTGRES_PASSWORD}
      POSTGRES_DB: aleta_master_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - aleta_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U aleta_admin -d aleta_master_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  # 2. DATABASE GRAFIK KURIKULUM MERDEKA (NEO4J)
  aleta_neo4j:
    image: neo4j:5.12-community
    container_name: aleta_neo4j
    restart: always
    environment:
      NEO4J_AUTH: neo4j/${ALETA_NEO4J_PASSWORD}
    volumes:
      - neo4j_data:/data
    networks:
      - aleta_network
    healthcheck:
      test: ["CMD-SHELL", "cypher-shell -u neo4j -p \"$ALETA_NEO4J_PASSWORD\" 'RETURN 1'"]
      interval: 15s
      timeout: 10s
      retries: 3

  # 3. PENYIMPANAN SESI BELAJAR REAL-TIME (REDIS)
  aleta_redis:
    image: redis:7-alpine
    container_name: aleta_redis
    restart: always
    command: redis-server --requirepass ${ALETA_REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - aleta_network

  # 4. INTELIGENCE HUB / LOCAL LLM ENGINE (OLLAMA)
  aleta_ollama:
    image: ollama/ollama:latest
    container_name: aleta_ollama
    restart: always
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - aleta_network
    # Catatan: Jika server lokal Yayasan memiliki GPU NVIDIA, aktifkan deploy runtime di bawah ini:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]

  # 5. CORE API BACKEND SERVICE (LAYER 2 ARCHITECTURE)
  aleta_core_api:
    build:
      context: ./backend_core
      dockerfile: Dockerfile
    container_name: aleta_core_api
    restart: always
    environment:
      - DATABASE_URL=postgresql://aleta_admin:${ALETA_POSTGRES_PASSWORD}@aleta_postgres:5432/aleta_master_db
      - REDIS_URL=redis://:${ALETA_REDIS_PASSWORD}@aleta_redis:6379/0
      - NEO4J_URI=bolt://aleta_neo4j:7687
      - NEO4J_USER=neo4j
      - NEO4J_PASSWORD=${ALETA_NEO4J_PASSWORD}
    depends_on:
      aleta_postgres:
        condition: service_healthy
      aleta_neo4j:
        condition: service_healthy
    networks:
      - aleta_network

  # 6. IDENTITY PROVIDER (KEYCLOAK SSO)
  aleta_keycloak:
    image: quay.io/keycloak/keycloak:24.0
    container_name: aleta_keycloak
    restart: always
    command: ["start", "--import-realm", "--proxy", "edge", "--hostname-strict=false"]
    environment:
      KEYCLOAK_ADMIN: ${ALETA_KEYCLOAK_ADMIN_USER}
      KEYCLOAK_ADMIN_PASSWORD: ${ALETA_KEYCLOAK_ADMIN_PASSWORD}
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://aleta_postgres:5432/keycloak_db
      KC_DB_USERNAME: ${ALETA_KEYCLOAK_DB_USER}
      KC_DB_PASSWORD: ${ALETA_KEYCLOAK_DB_PASSWORD}
      KC_HEALTH_ENABLED: "true"
    volumes:
      - keycloak_data:/opt/keycloak/data
      - ./infrastructure/keycloak:/opt/keycloak/data/import:ro
    depends_on:
      aleta_postgres:
        condition: service_healthy
    networks:
      - aleta_network
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:8080/health/ready || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 8

  # 7. AI ENGINE (BKT + RAG ORCHESTRATOR, dipisah dari core_api untuk scale-out)
  aleta_ai_engine:
    build:
      context: ./ai_engine
      dockerfile: Dockerfile
    container_name: aleta_ai_engine
    restart: always
    environment:
      - DATABASE_URL=postgresql://aleta_admin:${ALETA_POSTGRES_PASSWORD}@aleta_postgres:5432/aleta_master_db
      - NEO4J_URI=bolt://aleta_neo4j:7687
      - NEO4J_USER=neo4j
      - NEO4J_PASSWORD=${ALETA_NEO4J_PASSWORD}
      - OLLAMA_URL=http://aleta_ollama:11434
      - VECTOR_DB_URL=http://aleta_vector_db:6333
      - REDIS_URL=redis://:${ALETA_REDIS_PASSWORD}@aleta_redis:6379/1
    depends_on:
      aleta_postgres:
        condition: service_healthy
      aleta_neo4j:
        condition: service_healthy
    networks:
      - aleta_network

  # 8. VECTOR DB UNTUK RAG (QDRANT)
  aleta_vector_db:
    image: qdrant/qdrant:v1.9.2
    container_name: aleta_vector_db
    restart: always
    volumes:
      - vector_db_data:/qdrant/storage
    networks:
      - aleta_network

  # 9. DASHBOARD WEB GURU
  aleta_teacher_dashboard:
    build:
      context: ./teacher_dashboard_web
      dockerfile: Dockerfile
    container_name: aleta_teacher_dashboard
    restart: always
    networks:
      - aleta_network

  # 10. DASHBOARD WEB ADMIN YAYASAN
  aleta_admin_dashboard:
    build:
      context: ./admin_dashboard_web
      dockerfile: Dockerfile
    container_name: aleta_admin_dashboard
    restart: always
    networks:
      - aleta_network

  # 11. REVERSE PROXY & SECURITY SENTRY (NGINX EXPOSER)
  aleta_api_gateway:
    image: nginx:alpine
    container_name: aleta_api_gateway
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    depends_on:
      - aleta_core_api
      - aleta_keycloak
      - aleta_teacher_dashboard
      - aleta_admin_dashboard
    networks:
      - aleta_network

  # 12. JOB CADANGAN POSTGRES + NEO4J (cron via offen/docker-volume-backup)
  aleta_backup:
    image: offen/docker-volume-backup:v2.43.0
    container_name: aleta_backup
    restart: always
    environment:
      BACKUP_CRON_EXPRESSION: "0 2 * * *"
      BACKUP_FILENAME: "aleta-backup-%Y%m%dT%H%M%S.tar.gz"
      BACKUP_RETENTION_DAYS: "30"
      BACKUP_ENCRYPTION_PASSPHRASE: ${ALETA_BACKUP_PASSPHRASE}
    volumes:
      - postgres_data:/backup/postgres_data:ro
      - neo4j_data:/backup/neo4j_data:ro
      - keycloak_data:/backup/keycloak_data:ro
      - vector_db_data:/backup/vector_db_data:ro
      - backups:/archive
    networks:
      - aleta_network

```

---

## 4. KONFIGURASI ROUTING REVERSE PROXY (`nginx.conf`)

Buat berkas pendukung manajemen jaringan pada direktori `./nginx/nginx.conf` untuk mengarahkan lalu lintas data eksternal ke dalam sistem kontainer internal secara aman:

```nginx
events { worker_connections 1024; }

http {
    client_max_body_size 10m;
    proxy_connect_timeout 10s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    upstream core_api_server      { server aleta_core_api:8000; }
    upstream keycloak_server      { server aleta_keycloak:8080; }
    upstream teacher_dashboard    { server aleta_teacher_dashboard:80; }
    upstream admin_dashboard      { server aleta_admin_dashboard:80; }

    # Redirect semua HTTP ke HTTPS
    server {
        listen 80 default_server;
        return 301 https://$host$request_uri;
    }

    # API publik: api.aleta.yayasan.sch.id → core API
    server {
        listen 443 ssl;
        server_name api.aleta.yayasan.sch.id;

        ssl_certificate /etc/nginx/certs/api_fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/api_privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header X-Frame-Options "DENY" always;

        # SSE-friendly defaults untuk /api/v1/tutor/chat
        location /api/v1/tutor/chat {
            proxy_pass http://core_api_server;
            proxy_buffering off;
            proxy_cache off;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_read_timeout 600s;
        }

        location / {
            proxy_pass http://core_api_server;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # Keycloak: iam.aleta.yayasan.sch.id
    server {
        listen 443 ssl;
        server_name iam.aleta.yayasan.sch.id;
        ssl_certificate /etc/nginx/certs/iam_fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/iam_privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        location / {
            proxy_pass http://keycloak_server;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    # Teacher dashboard SPA
    server {
        listen 443 ssl;
        server_name guru.aleta.yayasan.sch.id;
        ssl_certificate /etc/nginx/certs/guru_fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/guru_privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        add_header Content-Security-Policy "default-src 'self'; connect-src 'self' https://api.aleta.yayasan.sch.id https://iam.aleta.yayasan.sch.id" always;
        location / { proxy_pass http://teacher_dashboard; }
    }

    # Admin yayasan dashboard SPA
    server {
        listen 443 ssl;
        server_name admin.aleta.yayasan.sch.id;
        ssl_certificate /etc/nginx/certs/admin_fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/admin_privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        location / { proxy_pass http://admin_dashboard; }
    }
}

```

### Contoh `.env.example`

```dotenv
ALETA_POSTGRES_PASSWORD=change_me_with_strong_random_value
ALETA_REDIS_PASSWORD=change_me_with_strong_random_value
ALETA_NEO4J_PASSWORD=change_me_with_strong_random_value
ALETA_JWT_ISSUER=https://aleta-iam.yayasan.sch.id/realms/aleta
ALETA_JWT_AUDIENCE=aleta-api
ALETA_KEYCLOAK_ADMIN_USER=admin
ALETA_KEYCLOAK_ADMIN_PASSWORD=change_me_with_strong_random_value
ALETA_KEYCLOAK_DB_USER=keycloak_admin
ALETA_KEYCLOAK_DB_PASSWORD=change_me_with_strong_random_value
ALETA_BACKUP_PASSPHRASE=change_me_with_strong_random_value
```

---

## 5. PROSEDUR INSTALASI SEKALI KLIK (DEPLOYMENT COMMANDS)

Berikut adalah instruksi baris perintah (*terminal commands*) untuk menyalakan infrastruktur ALETA pada sistem operasi Linux Server (Ubuntu/Debian) milik Yayasan:

### Langkah Awal: Mengunduh Model Kecerdasan Buatan (Local LLM Llama 3)

Setelah seluruh kontainer menyala untuk pertama kali, jalankan perintah ini ke dalam kontainer Ollama untuk mengunduh model bahasa pintar secara lokal yang akan berfungsi sebagai asisten guru dan siswa tanpa biaya token internet:

```bash
# 1. Nyalakan seluruh ekosistem server ALETA di latar belakang
docker compose up -d

# 2. Perintahkan kontainer Ollama untuk mengunduh model bahasa Llama 3 (8 Miliar Parameter)
docker exec -it aleta_ollama ollama run llama3

# 3. Periksa status operasional seluruh kontainer
docker compose ps

```

---

## 6. CAPACITY PLANNING & HARDWARE SIZING PILOT

> **BARU**: Sizing realistis untuk pilot production. Target: 1 unit SMP, 200 siswa aktif, 20 guru, 50 parent.

### A. Pilot Scope (MVP Phase 1)

| Metric | Target Pilot |
| :--- | :--- |
| Unit Sekolah | 1 (SMP) |
| Siswa Aktif | 10–20 (alpha), 50–100 (beta), 200 (production pilot) |
| Guru Aktif | 5 (alpha), 10 (beta), 20 (production) |
| Parent Aktif | 20–40 |
| Mata Pelajaran | 1 (Matematika alpha), 3 (beta), 5 (production) |
| TP Count | 50 (alpha), 200 (beta), 500 (production) |
| Concurrent Users Peak | 30 (jam belajar 08:00–10:00, 13:00–15:00) |
| RPS Target (Median) | 10 RPS |
| RPS Target (Peak) | 50 RPS (quiz submit spike) |

### B. Hardware Sizing (Bare Metal / Cloud VM)

**Minimum Specs (Alpha 10–20 siswa)**:
* CPU: 4 cores (x86_64, AVX2 support untuk Ollama)
* RAM: 16 GB
* GPU: NVIDIA GTX 1660 Ti / RTX 3060 (6 GB VRAM min) untuk Ollama llama3:8b
* Storage: 100 GB SSD (NVMe recommended)
* Network: 100 Mbps up/down

**Recommended Specs (Production Pilot 200 siswa)**:
* CPU: 8 cores (Intel Xeon / AMD EPYC)
* RAM: 32 GB
* GPU: NVIDIA RTX 4060 Ti / A4000 (16 GB VRAM) untuk Ollama + embedding parallel
* Storage: 250 GB NVMe SSD (OS + containers + DB + backups)
* Network: 1 Gbps

**Storage Breakdown**:
* PostgreSQL data: ~5 GB (200 siswa × 500 TP × 50 quiz attempts avg)
* Neo4j data: ~2 GB (500 TP + prerequisite graph + content items)
* Qdrant vectors: ~3 GB (5000 content chunks × nomic-embed-text 768-dim)
* Ollama models: ~8 GB (llama3:8b-instruct + nomic-embed-text)
* Docker images: ~12 GB
* Logs (30 hari): ~5 GB
* Backup retention (30 hari): ~50 GB (compressed)
* OS + swap: ~20 GB
* **Total**: ~105 GB (alpha), ~200 GB (production pilot dengan margin)

### C. Service Resource Allocation (docker-compose resources)

```yaml
# Tambahkan di docker-compose.yml per service
services:
  aleta_ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
        limits:
          memory: 12G  # 8 GB model + 4 GB context window
          cpus: '4.0'

  aleta_core_api:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

  aleta_ai_engine:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

  aleta_postgres:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

  aleta_neo4j:
    deploy:
      resources:
        limits:
          memory: 3G
          cpus: '1.5'

  aleta_qdrant:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'

  aleta_redis:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  aleta_keycloak:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### D. Performance Targets

| Metric | Target P50 | Target P95 | Alerting Threshold |
| :--- | :--- | :--- | :--- |
| `/api/v1/engine/evaluate` latency | 180 ms | 420 ms | > 600 ms |
| `/api/v1/student/next-content` latency | 120 ms | 300 ms | > 500 ms |
| `/api/v1/tutor/chat` (streaming) TTFB | 800 ms | 2400 ms | > 4000 ms |
| Ollama inference (llama3:8b, 256 tokens) | 1200 ms | 2800 ms | > 5000 ms |
| Ollama queue depth | 0 | 3 | > 5 (warning), > 10 (critical) |
| PostgreSQL query (passport read) | 8 ms | 25 ms | > 50 ms |
| Neo4j query (prerequisite traverse) | 12 ms | 40 ms | > 100 ms |
| Qdrant vector search (k=5) | 15 ms | 45 ms | > 80 ms |

### E. Backup Strategy & RTO/RPO

**Backup Schedule** (via `offen/docker-volume-backup`):
* **Frequency**: Daily at 02:00 WIB (cron `0 2 * * *`)
* **Retention**: 30 hari (rolling, otomatis delete old backups)
* **Encryption**: AES-256 dengan `BACKUP_ENCRYPTION_PASSPHRASE` (env secret)
* **Target**: `/backups/aleta/` (local volume, rsync ke offsite NAS/S3 via cron)
* **Scope**: PostgreSQL volumes + Neo4j volumes (Keycloak DB jika pakai Postgres realm)

**RTO (Recovery Time Objective)**: **≤ 2 jam**
* Restore dari backup terenkripsi
* Spin up containers
* Validate data integrity
* Smoke test login + quiz flow

**RPO (Recovery Point Objective)**: **≤ 24 jam**
* Backup harian 02:00
* Jika disaster terjadi jam 01:00, kehilangan maksimal 23 jam data
* Untuk production strict, tingkatkan ke backup setiap 6 jam (cron `0 */6 * * *`) → RPO ≤ 6 jam

**Restore Test** (mandatory setiap bulan):
```bash
# Simulasi restore dari backup terbaru
cd /backups/aleta/
LATEST=$(ls -t aleta-backup-*.tar.gz | head -1)
mkdir restore_test
tar -xzf $LATEST -C restore_test/
docker-compose -f docker-compose.restore.yml up -d  # Test compose dengan volume restore
# Verify: login, query passport, submit quiz
docker-compose -f docker-compose.restore.yml down
rm -rf restore_test/
```

### F. Monitoring & Alerting Thresholds

**Prometheus Metrics** (via `/metrics` endpoint each service):
* `http_request_duration_seconds` (histogram, P50/P95/P99)
* `ollama_queue_depth` (gauge)
* `ollama_gpu_utilization_percent` (gauge)
* `ollama_vram_used_mb` (gauge)
* `postgres_active_connections` (gauge)
* `redis_memory_used_mb` (gauge)

**Grafana Dashboards**:
1. **System Health**: CPU, RAM, GPU, disk, network per container
2. **API Performance**: Latency heatmap per endpoint, error rate, RPS
3. **LLM Metrics**: Ollama latency, queue depth, GPU util, token/sec
4. **Database**: Postgres slow queries, Neo4j query time, Qdrant latency
5. **Business**: Active sessions, quiz submissions per hour, tutor handoff count

**Alert Rules** (via Grafana Alerting / Prometheus Alertmanager):
* `ollama_queue_depth > 5` for 10 min → WARNING (email guru/admin)
* `ollama_queue_depth > 10` for 5 min → CRITICAL (SMS admin)
* `api_p95_latency > threshold` for 15 min → WARNING
* `postgres_connections > 80%` max → WARNING
* `disk_usage > 85%` → CRITICAL
* `backup_failed` (last 48 hours) → CRITICAL

### G. Scaling Path (Post-Pilot)

Jika pilot sukses dan perlu scale ke 500+ siswa atau multi-unit:
1. **Horizontal scale backend**: Deploy 2–3 replicas `aleta_core_api` + `aleta_ai_engine` behind nginx load balancer.
2. **Dedicated GPU node**: Pindahkan Ollama ke dedicated GPU server (RTX 4090 / A6000).
3. **Database read replicas**: Postgres read replica untuk dashboard analytics, write ke primary.
4. **Kubernetes migration**: Pindah dari docker-compose ke k8s (Helm charts), auto-scaling HPA.
5. **Managed services**: Gunakan managed Postgres (RDS/CloudSQL), managed Redis, managed vector DB jika cloud.

---

## 7. PENUTUP

Dengan mengeksekusi prosedur di atas dan mengikuti capacity planning §6, seluruh komponen arsitektur inti, logika kurikulum, basis data multi-tenant, dan mesin kecerdasan buatan dari **Project ALETA** telah aktif sepenuhnya dan siap melayani proses transformasi digital pendidikan terpadu di lingkungan Yayasan Anda.

Selamat! Seluruh **8 dokumen utama cetak biru teknis (*comprehensive blueprints*) Project ALETA** lingkup Yayasan terpadu (TK, SD, SMP, SMA) telah sukses kita susun secara utuh, mendalam, integratif, dan *ready untuk konsumsi vibe coding*. 

Semua file ini dirancang saling mengikat: logika ontologi kurikulum di file 01 dibaca oleh algoritma BKT di file 02, dicatat transaksinya pada tabel PostgreSQL di file 03, dikomunikasikan lewat kontrak API di file 04, dikonversi menjadi dynamic UI Flutter di file 05 dan dasbor React di file 06, dilindungi protokol hukum UU PDP di file 07, dan dibungkus otomatis lewat Docker Compose di file 08.

Rangkaian cetak biru ini sudah siap Anda masukkan ke program IDE cerdas (seperti Cursor, Windsurf, atau repositori LLM) untuk langsung memproduksi baris kode aplikasi nyatanya. Semoga Project ALETA berjalan sukses dan menjadi pelopor revolusi pendidikan cerdas yang memanusiakan guru dan murid!

```
