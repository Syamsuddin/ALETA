---
doc: "13"
title: "Migrations and CI/CD"
scope: "Alembic + Neo4j migrations, OpenAPI CI gate, Gitea Actions workflow, Keycloak realm export, backup off-site"
key_entities: [Alembic, alembic_version, neo4j_migrations, openapi_gate.sh, Gitea_Actions, backup_cron]
depends_on: ["03", "08"]
loaded_by_tasks: [T-005, T-109, T-803]
---

# FILE: 13_MIGRATIONS_AND_CICD.md
# PROJECT ALETA: MIGRATIONS, OPENAPI, CI/CD, & BACKUP SPECIFICATION

## 1. PENDAHULUAN

Dokumen ini menutup gap P4 (production hardening) yang tidak ditangani Doc 03/04/07/08: bagaimana skema database di-versi-kontrol, bagaimana OpenAPI dipublikasikan, bagaimana pipeline CI/CD melindungi release, dan bagaimana Keycloak realm + Neo4j constraints di-bootstrap.

---

## 2. POSTGRES MIGRATIONS (ALEMBIC)

### A. Struktur Folder
```
backend_core/
  alembic.ini
  alembic/
    env.py
    versions/
      20260101_0001_initial_core_schema.py
      20260101_0002_passport_and_affective.py
      20260101_0003_misconceptions_session_state.py
      20260101_0004_consent_transition.py
      20260101_0005_tutor_modul_ajar.py
      20260101_0006_audit_events.py
      20260101_0007_unit_smp_schema.py
      ...
```

### B. Konvensi
* Setiap PR yang mengubah skema **wajib** menyertakan migration baru, tidak boleh edit migration lama.
* Penamaan file: `YYYYMMDD_NNNN_<snake_case_summary>.py`.
* Skema tenant (`unit_*`) di-generate dari template parametrik di `backend_core/alembic/tenant_template/` agar konsisten — saat tenant baru ditambah via Admin Dashboard, server menjalankan `apply_tenant_template(schema_name)`.

### C. Perintah Operasional
```bash
# Local dev
alembic upgrade head
alembic revision --autogenerate -m "add_xyz_table"

# Production (jalankan dari container core_api dengan flag explicit)
docker exec aleta_core_api alembic -x env=production upgrade head
```

### D. Rollback Policy
* Migrasi non-destruktif (`add column nullable`, `create table`) selalu reversibel.
* Migrasi destruktif (`drop`, `rename`) memerlukan dua-langkah deploy (additive → cutover → cleanup) dan PR review label `db-destructive`.

---

## 3. NEO4J CONSTRAINTS & SEED

### A. Bootstrap Script
`backend_core/backend_core/scripts/neo4j_bootstrap.cypher` berisi seluruh `CREATE CONSTRAINT` dari `01_CURRICULUM_ONTOLOGY_GRAPH.md` §5.A + seed minimal Institution/Unit untuk dev.

### B. Migration Tool
Pakai konvensi sederhana: file di `backend_core/neo4j_migrations/VNNN__description.cypher` (di service root, lihat `15_PROJECT_STRUCTURE.md` §3), runner Python di `backend_core/backend_core/scripts/run_neo4j_migrations.py` yang menyimpan versi terapan ke node `(:_SchemaVersion {version: NNN, applied_at: ...})`.

---

## 4. OPENAPI SPEC

### A. Export
FastAPI sudah generate OpenAPI otomatis. Tambahkan job:
```bash
docker exec aleta_core_api python -m backend_core.scripts.export_openapi \
  > backend_core/openapi.yaml
```
Job ini **wajib dijalankan dalam CI** (lihat §5) dan diff vs. file commit; jika berbeda, CI gagal — memaksa developer commit spec terbaru bersama perubahan kode.

### B. Konsumsi Frontend
* Teacher Dashboard & Admin Dashboard generate TypeScript client via `openapi-typescript` saat build.
* Flutter generate Dart client via `openapi-generator-cli` ke `frontend_flutter/lib/core/api/generated/`.

---

## 5. CI/CD PIPELINE

### A. Provider
Yayasan default: **Gitea Actions** (self-hosted) untuk menjaga kedaulatan data. Skrip kompatibel dengan GitHub Actions sebagai cadangan.

### B. Workflow `ci.yml` (ringkas)
```yaml
name: ci
on: [pull_request, push]
jobs:
  backend:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r backend_core/requirements-dev.txt
      - run: ruff check backend_core
      - run: pytest backend_core/tests --cov --cov-report=xml
      - run: alembic -c backend_core/alembic.ini upgrade head
        env:
          DATABASE_URL: postgresql://test@localhost:5432/test
      - run: python -m backend_core.scripts.export_openapi > /tmp/openapi.yaml
      - run: diff /tmp/openapi.yaml backend_core/openapi.yaml

  flutter:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
        working-directory: frontend_flutter
      - run: flutter analyze
        working-directory: frontend_flutter
      - run: flutter test
        working-directory: frontend_flutter

  web:
    runs-on: self-hosted
    strategy: { matrix: { app: [teacher_dashboard_web, admin_dashboard_web] } }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20" }
      - run: npm ci
        working-directory: ${{ matrix.app }}
      - run: npm run lint
        working-directory: ${{ matrix.app }}
      - run: npm test -- --run
        working-directory: ${{ matrix.app }}
      - run: npm run build
        working-directory: ${{ matrix.app }}

  security:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - run: pip install bandit pip-audit
      - run: bandit -r backend_core
      - run: pip-audit -r backend_core/requirements.txt
      - run: trivy fs --severity HIGH,CRITICAL .
      - run: gitleaks detect --no-banner
```

### C. Release Gate (deploy)
Trigger manual `release.yml` setelah tag `vX.Y.Z`. Pipeline:
1. Build & push image ke registry internal (`registry.yayasan.sch.id/aleta/*`).
2. Sign image dengan cosign.
3. Trivy scan ulang image.
4. Backup snapshot Postgres + Neo4j (lihat §7) sebelum rollout.
5. Rolling restart via `docker compose up -d --no-deps <service>`.
6. Smoke test endpoint `/api/v1/health`.

---

## 6. KEYCLOAK REALM EXPORT

### A. Lokasi
`infrastructure/keycloak/aleta-realm.json` — diimpor otomatis saat `aleta_keycloak` start (`--import-realm`, lihat Doc 08 §3).

### B. Isi minimum
* Realm `aleta`.
* Clients: `aleta-api` (confidential, RS256), `aleta-flutter` (public, PKCE), `aleta-teacher-web` (public, PKCE), `aleta-admin-web` (public, PKCE, MFA required).
* Roles: `SUPERADMIN`, `ADMIN_YAYASAN`, `GURU`, `SISWA`, `ORANG_TUA`.
* Protocol mappers: `tenant_id`, `schema_scope`, `fase_aktif`, `role` → masuk ke token claims (lihat Doc 07 §2).
* Brute force settings: max 5 failures, lockout 15 menit.
* MFA Required Action untuk role `SUPERADMIN`, `ADMIN_YAYASAN`, `GURU`.

### C. Update Flow
1. Edit di Keycloak UI dev.
2. Export realm via `kc.sh export --realm aleta --file /tmp/aleta-realm.json`.
3. Commit ke repo.
4. CI memvalidasi JSON parse.

---

## 7. BACKUP & RESTORE

### A. Backup Otomatis
Service `aleta_backup` (Doc 08 §3) menjalankan tar+enkripsi setiap 02:00. Output: `/archive/aleta-backup-YYYYMMDDTHHMMSS.tar.gz` (encrypted via `BACKUP_ENCRYPTION_PASSPHRASE`).

### B. Off-site Sync
Cron pada host menyalin file ke storage off-site (S3-compatible MinIO yayasan / Wasabi):
```bash
0 4 * * * rclone copy /var/lib/docker/volumes/aleta_backups/_data minio:aleta-backups
```

### C. Restore Test (Quarterly)
1. Bangkitkan stack staging dari snapshot tertentu.
2. Jalankan smoke test (`pytest tests/smoke`).
3. Bandingkan checksum table sample.
Hasil test dicatat di `docs/ops/restore-tests.md`.

---

## 8. LOG AGGREGATION

* **Stack:** Loki + Promtail + Grafana, di-host pada `aleta_log_stack` (compose extension `docker-compose.observability.yml`).
* Setiap kontainer aplikasi memakai driver `json-file` dengan rotation `max-size=20m max-file=5`.
* Promtail tail file → Loki → Grafana dashboards default:
  * `Auth events` (login fail, MFA failure).
  * `Engine evaluate latency`.
  * `Ollama response time`.
  * `Audit events stream` (filter by `risk_level`).

---

## 9. RELEASE GATE FINAL CHECKLIST

* [ ] Alembic head == latest commit migration.
* [ ] OpenAPI diff bersih.
* [ ] Bandit + pip-audit + trivy clear (HIGH/CRITICAL = 0).
* [ ] Gitleaks tidak menemukan secret.
* [ ] Backup terakhir berusia ≤ 24 jam.
* [ ] Test restore terakhir ≤ 90 hari.
* [ ] Keycloak realm export sinkron dengan production.
* [ ] Smoke test post-deploy hijau.
