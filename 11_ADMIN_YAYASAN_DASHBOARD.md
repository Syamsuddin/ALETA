---
doc: "11"
title: "Admin Yayasan Dashboard"
scope: "React admin dashboard: ATP Builder (react-flow), system_config runtime calibration, audit log explorer"
key_entities: [ATP_Builder, SystemConfigPanel, AuditLogExplorer, OpsHealthPanel, "/admin/system-config"]
depends_on: ["04", "01", "14"]
loaded_by_tasks: [T-607, T-608, T-609, T-610, T-611]
---

# FILE: 11_ADMIN_YAYASAN_DASHBOARD.md
# PROJECT ALETA: ADMIN YAYASAN DASHBOARD SPECIFICATION

## 1. PENDAHULUAN

Dashboard Admin Yayasan adalah aplikasi React terpisah (`admin_dashboard_web/`) yang dipakai oleh peran `ADMIN_YAYASAN` dan `SUPERADMIN`. Fokus: tata kelola lintas-unit, KPI strategik, kurasi kurikulum tingkat yayasan, dan kontrol operasional sistem ALETA.

Berbeda dengan Teacher Dashboard (Doc 06) yang berorientasi tindakan harian di kelas, dashboard ini berorientasi *governance & strategy*.

> ⚠️ **MVP SCOPE**: Untuk pilot phase pertama, Admin Dashboard **hanya** implement modul: Overview (read-only), Users (read-only), Audit Log, Ops Health, dan System Config (read-only). Modul CRUD unit/curriculum/ATP ditunda ke post-MVP. Lihat §2 untuk detail.

---

## 2. PETA MODUL (MVP vs Post-MVP)

> **CANONICAL**: Lihat `MVP_SCOPE.md` untuk irisan pilot end-to-end.

| Modul | URL | Fungsi | Phase |
| :--- | :--- | :--- | :--- |
| Overview | `/` | KPI lintas-unit (mastery, red flag, health) | **MVP** (read-only) |
| Audit Log | `/audit` | Eksplorasi `audit_events` dengan filter | **MVP** (read-only) |
| Operasional | `/ops` | Healthcheck Postgres/Neo4j/Ollama, queue depth, metrics | **MVP** (read-only) |
| Sistem Konfigurasi | `/system` | Threshold BKT, LLM enable/disable flags | **MVP** (read-only view, edit gated) |
| Manajemen Pengguna | `/users` | List users per tenant dengan role | **MVP** (read-only, no CRUD) |
| Transisi Siswa | `/transitions` | Bulk transition antar unit (Doc 12) | **MVP** (simplified: single student, manual approval) |
| Consent & PDP | `/consent` | Audit consent requests + status | **MVP** (read-only audit) |
| Tata Kelola Unit | `/units` | CRUD tenant, mapping schema | **Post-MVP** |
| Kurasi Kurikulum | `/curriculum` | Editor TP/CP/Misconception, sync Neo4j | **Post-MVP** |
| ATP Builder | `/curriculum/atp` | Drag-drop visual ATP builder | **Post-MVP** |

**MVP Acceptance Criteria**:
* [ ] Admin dapat login dengan MFA.
* [ ] Admin dapat view KPI overview lintas unit (data 7 hari terakhir).
* [ ] Admin dapat query audit log dengan filter: actor, action, date range, risk_level.
* [ ] Admin dapat view system health real-time (service status, latency P95, queue depth).
* [ ] Admin dapat view system config (BKT thresholds, LLM flags) — read-only.
* [ ] Admin dapat view list users per unit — read-only, no create/edit/delete.
* [ ] Admin dapat trigger single student transition dengan manual approval flow (no bulk CSV upload).

**Post-MVP Features** (defer to Phase 2):
* CRUD units/tenants.
* CRUD users (create teacher/student accounts, assign roles, reset password).
* Curriculum editor (create/edit TP, CP, prerequisite edges, misconception nodes).
* ATP Builder visual drag-drop canvas (react-flow).
* Bulk transition CSV upload.
* Data export PDP dengan approval workflow.

Semua route diproteksi guard `role ∈ {ADMIN_YAYASAN, SUPERADMIN}` dan **MFA wajib** (Doc 07 §B).

---

## 3. STACK

Identik dengan Teacher Dashboard (Doc 06 §5): Vite + React 18 + TS + TanStack Query + Zustand + Tailwind + React Router 6.

Tambahan untuk admin:
* `react-flow` untuk ATP Builder (drag-drop graph).
* `@tanstack/react-table` untuk tabel audit.
* `recharts` untuk KPI charts.

---

## 4. KONTRAK DATA UTAMA

### A. Overview KPI

`GET /api/v1/admin/yayasan/overview` (Doc 04 §3.M). Tambahan field yang harus di-render:
```json
{
  "academic_year": "2025/2026",
  "kpi_cards": [
    { "label": "Total Siswa Aktif", "value": 4820 },
    { "label": "Avg Mastery (semua TP)", "value": 0.68 },
    { "label": "Red Flag Rate (7 hari)", "value": 0.04 },
    { "label": "Consent Pending", "value": 12 }
  ]
}
```

### B. Curriculum Editor

`PUT /api/v1/admin/curriculum/tp` payload:
```json
{
  "tp_id": "TP_MAT_7_ALJABAR",
  "competency": "Menyederhanakan",
  "content": "Bentuk Aljabar Linear",
  "bloom_level": 3,
  "derived_from_cp_id": "CP_MAT_SMP_ALJ",
  "prerequisites": ["TP_MAT_6_PERSAMAAN"],
  "may_trigger_misconceptions": ["MIS_OP_ORDER"]
}
```
Server menjalankan transaksi 2-phase: tulis ke Postgres dulu (audit), lalu MERGE ke Neo4j. Jika Neo4j gagal, rollback Postgres.

### C. ATP Builder

Frontend ATP Builder mengirim seluruh `ATPSequence.position_map` baru dalam satu PUT, server replace atomic.

---

## 5. SYSTEM CONFIGURATION

Tabel `aleta_core.system_config` adalah key-value store untuk parameter yang boleh dikalibrasi tim yayasan tanpa redeploy.

```sql
CREATE TABLE aleta_core.system_config (
    config_key VARCHAR(80) PRIMARY KEY,
    config_value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES aleta_core.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

Key wajib (seed migration):
| Key | Tipe | Default | Diatur di modul |
| :--- | :--- | :--- | :--- |
| `redflag.consecutive_sessions` | int | 3 | System |
| `redflag.wrong_ratio_threshold` | float | 0.70 | System |
| `redflag.slowdown_p95_factor` | float | 1.5 | System |
| `redflag.open_misconception_min` | int | 2 | System |
| `bkt.mastery_threshold` | float | 0.85 | System |
| `bkt.remedial_threshold` | float | 0.20 | System |
| `llm.default_model` | string | `llama3:8b-instruct` | System |
| `llm.rewrite_temperature` | float | 0.3 | System |
| `retention.quiz_logs_days` | int | 1095 | System |
| `retention.tutor_messages_days` | int | 90 | System |

Mengubah salah satu nilai memicu `audit_events` `action='SYSTEM_CONFIG_CHANGE'` dengan `risk_level='HIGH'`.

---

## 6. AUDIT LOG EXPLORER

UI sederhana dengan filter:
* Range waktu (default 24 jam terakhir).
* `actor_role`, `action`, `risk_level`, `tenant_id`.
* Full-text search di `target_id` dan `reason`.

Eksport CSV harus melalui consent + log `action='AUDIT_EXPORT'`.

---

## 7. OPERATIONAL HEALTH PANEL

Endpoint `GET /api/v1/admin/ops/health` mengumpulkan:
```json
{
  "services": [
    { "name": "postgres", "status": "UP", "latency_ms": 4 },
    { "name": "neo4j", "status": "UP", "latency_ms": 12 },
    { "name": "ollama", "status": "DEGRADED", "latency_ms": 6800, "note": "GPU offload disabled" },
    { "name": "qdrant", "status": "UP", "latency_ms": 9 },
    { "name": "redis", "status": "UP", "latency_ms": 1 }
  ],
  "queues": [
    { "name": "modul_ajar_generation", "depth": 3 },
    { "name": "transition_jobs", "depth": 0 }
  ],
  "backup": { "last_success_at": "2026-05-23T02:01:00Z", "size_mb": 4823 }
}
```

Status `DEGRADED` memicu warning kuning; `DOWN` merah dengan tombol "Buka playbook" yang membuka `docs/incidents/runbook.md`.

---

## 8. RELEASE GATE ADMIN DASHBOARD

* RBAC test: percobaan akses dengan role `GURU` harus 403.
* MFA bypass test: gagal mfa harus tetap blocked.
* Audit completeness test: setiap aksi mutasi harus menghasilkan baris `audit_events`.
* Snapshot test ATP Builder: drag → simpan → reload tetap konsisten.
