---
doc: "04"
title: "Backend API Contracts"
scope: "FastAPI REST endpoint specs, request/response schemas, SecurityGuard auth flow, error envelope"
key_entities: ["POST /engine/evaluate", "GET /student/passport", "POST /auth/login", SecurityGuard, StandardResponse]
depends_on: ["03", "07", "GLOSSARY"]
loaded_by_tasks: [T-106, T-107, T-108, T-207, T-208, T-210]
canonical_reference: "GLOSSARY.md untuk semua endpoint paths, error codes, adaptive_status values, consent_scope"
---

# FILE: 04_BACKEND_API_CONTRACTS.md
# PROJECT ALETA: BACKEND API CONTRACTS SPECIFICATION

> ⚠️ **CANONICAL**: Semua endpoint, error codes, enum values, dan field names WAJIB mengikuti `GLOSSARY.md` (frozen 2026-05-24). OpenAPI spec adalah single source of truth untuk client code generation.

## 1. PENDAHULUAN & PROTOKOL STANDAR
Dokumen ini mendefinisikan kontrak komunikasi data (API Endpoints) antara aplikasi *frontend* (Flutter/React) dengan *backend core services* ALETA. 

### Aturan Protokol Global:
*   **Format Data:** HTTP REST dengan format bawaan (payload) berupa `application/json`.
*   **Header Autentikasi:** `Authorization: Bearer <JWT_TOKEN>` wajib disertakan pada seluruh endpoint kecuali rute login/registrasi.
*   **Skema Multi-Tenancy:** Identitas skema unit sekolah diekstrak secara otomatis oleh backend dari klaim token JWT (`tenant_id`).
*   **Authorization Object-Level:** Setiap endpoint yang menerima `student_id`, `class_id`, `tenant_id`, atau resource ID lain wajib memvalidasi kepemilikan objek sesuai matrix di `07_SECURITY_PRIVACY_PASSPORT.md`.
*   **Abuse Protection:** Endpoint login, evaluasi kuis, dashboard, dan LLM wajib memakai rate limit berbasis Redis, validasi payload ketat, timeout, dan error response tanpa stack trace.
*   **Format Respons Sukses:**

```json
{
  "success": true,
  "message": "Pesan status operasional",
  "data": {}
}
```

*   **Format Respons Error Standar (RFC 7807-inspired):**

> **CANONICAL**: Error codes mengikuti `GLOSSARY.md` §4 (Application-Level Error Codes).

```json
{
  "success": false,
  "error": {
    "code": "PARENT_OWNERSHIP_FAILED",
    "message": "Orang tua tidak memiliki akses ke siswa ini",
    "request_id": "req_8f3a2b1c",
    "details": {"student_id": "...", "parent_id": "..."}
  }
}
```

**Error Code Categories** (lihat GLOSSARY.md §4 untuk daftar lengkap):

| HTTP | Code Examples | Arti |
| :--- | :--- | :--- |
| 400 | `VALIDATION_*`, `EXPORT_REASON_REQUIRED` | Payload salah / field required hilang |
| 401 | `INVALID_TOKEN`, `MFA_REQUIRED` | Token hilang/expired/invalid |
| 403 | `ROLE_INSUFFICIENT`, `TENANT_MISMATCH`, `STUDENT_OWNERSHIP_FAILED`, `PARENT_OWNERSHIP_FAILED`, `TEACHER_OWNERSHIP_FAILED`, `EXPORT_CONSENT_REQUIRED` | Role atau ownership tidak cocok |
| 404 | `NOT_FOUND_*` | Resource tidak ada / di luar scope tenant |
| 409 | `CONSENT_ALREADY_DECIDED`, `OFFLINE_CONFLICT` | Conflict / race condition |
| 422 | `PREREQUISITE_BROKEN` | Business logic error |
| 429 | `RATE_LIMIT` | Rate limit tercapai |
| 500 | `INTERNAL_*` | Unhandled exception (no stack trace) |
| 503 | `MODEL_UNAVAILABLE`, `GRAPH_UNAVAILABLE` | Service dependency down |

*   **Pagination:** Endpoint list memakai cursor-based pagination dengan query param `?cursor=…&limit=50` (default 50, maks 200). Respons membawa `data.next_cursor` (nullable).
*   **Idempotency:** Endpoint mutasi (`/engine/evaluate`, `/consent/*`, `/admin/transition`) wajib menerima header `Idempotency-Key: <uuid>`. Server menyimpan hasil di Redis selama 24 jam.
*   **OpenAPI:** Skema lengkap di-export ke `backend_core/openapi.yaml` via `fastapi.openapi()`. Lihat `13_MIGRATIONS_AND_CICD.md` §4.

---

## 2. API ENDPOINTS MAPPING

> **CANONICAL**: Semua endpoint di tabel ini wajib ada di OpenAPI spec. Client generate dari OpenAPI, tidak hardcode.

### Auth & Core

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/login` | Autentikasi via Keycloak & token JWT | Semua |
| `POST` | `/api/v1/auth/refresh` | Refresh token rotation | Semua |
| `POST` | `/api/v1/auth/logout` | Invalidate refresh token | Semua |
| `GET` | `/api/v1/notifications` | List notifikasi user | Semua |
| `PUT` | `/api/v1/notifications/:id/read` | Mark notification read | Semua |

### Student Endpoints

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/student/passport` | Paspor Kognitif 12 tahun | Siswa, Guru, Ortu |
| `GET` | `/api/v1/student/next-content` | ContentItem berikutnya (ATP + state machine) | Siswa |
| `POST` | `/api/v1/engine/evaluate` | Submit jawaban & BKT update | Siswa |
| `POST` | `/api/v1/tutor/chat` | Streaming chat tutor (SSE) | Siswa |

### Teacher Endpoints

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/teacher/dashboard/summary` | Differentiation grouping & red flags | Guru |
| `GET` | `/api/v1/teacher/morning-briefing` | Briefing taktis pra-kelas | Guru |
| `POST` | `/api/v1/teacher/modul-ajar/generate` | Trigger generator Modul Ajar (Ollama) | Guru |
| `GET` | `/api/v1/teacher/modul-ajar/:draft_id` | Poll/ambil draft Modul Ajar | Guru |

### Parent Endpoints

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/parent/children` | **BARU**: List anak + weekly summary | Orang Tua |
| `GET` | `/api/v1/parent/activity-reflection` | **BARU**: Weekly narrative report (LLM) | Orang Tua |
| `GET` | `/api/v1/parent/child-report` | Detail perkembangan anak per period | Orang Tua |
| `GET` | `/api/v1/parent/home-activities` | Saran aktivitas rumah kontekstual | Orang Tua |
| `POST` | `/api/v1/parent/consent` | **ALIAS**: Grant/deny consent (sama dengan `/consent/:id/decision`) | Orang Tua |

### Consent Endpoints

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/consent/request` | Request consent dari parent | Guru, Admin |
| `POST` | `/api/v1/consent/:id/decision` | Parent decide consent (GRANTED/DENIED) | Orang Tua |
| `GET` | `/api/v1/consent/active` | List consent aktif untuk siswa | Ortu, Admin |

### Admin Endpoints

| Method | Endpoint | Fungsi Utama | Akses |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/admin/yayasan/overview` | KPI lintas-unit dashboard | Admin Yayasan |
| `GET` | `/api/v1/admin/audit-log` | **BARU**: Audit trail query | Admin Yayasan |
| `GET` | `/api/v1/admin/ops-health` | **BARU**: Real-time system health | Admin Yayasan |
| `GET` | `/api/v1/admin/system-config` | **BARU**: Runtime config read | Admin Yayasan |
| `PUT` | `/api/v1/admin/system-config` | **BARU**: Update runtime config | Admin Yayasan |
| `POST` | `/api/v1/admin/transition` | Single student transition | Admin Yayasan |
| `POST` | `/api/v1/admin/transition/bulk` | **BARU**: Batch transition lintas jenjang | Admin Yayasan |

---

## 3. DETAIL SPESIFIKASI KONTRAK DATA (JSON PAYLOAD)

### A. Autentikasi Pengguna (`POST /api/v1/auth/login`)
Digunakan oleh aplikasi apa pun untuk memvalidasi kredensial pengguna terpusat.

#### Request Body:
```json
{
  "email": "sandi.putra@yayasan.sch.id",
  "password": "PasswordRahasia123"
}

```

#### Response (200 OK):

```json
{
  "success": true,
  "message": "Autentikasi berhasil.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user_id": "7b8971f4-3d0b-4813-bc7c-d6981881e1a1",
    "full_name": "Sandi Putra",
    "role": "SISWA",
    "tenant_id": "UNIT_SMP_01"
  }
}

```

---

### B. Pengambilan Paspor Kognitif (`GET /api/v1/student/passport`)

Mengembalikan status penguasaan seluruh materi pembelajaran siswa yang digabungkan dari histori database relasional dan grafik.

#### Query Parameters:

* `student_id` (UUID, Opsional): Wajib diisi oleh Guru/Ortu untuk melihat data siswa terkait. Untuk siswa, otomatis membaca ID dari token JWT.
  * Guru hanya boleh mengakses siswa di kelas yang diajar.
  * Orang tua hanya boleh mengakses siswa yang terhubung di `student_parent_relations`.
  * Siswa tidak boleh mengirim `student_id` milik pengguna lain.

#### Response (200 OK):

```json
{
  "success": true,
  "message": "Paspor Kognitif berhasil ditarik.",
  "data": {
    "student_id": "7b8971f4-3d0b-4813-bc7c-d6981881e1a1",
    "fase_aktif": "FASE_D",
    "total_mastered_tps": 42,
    "passports": [
      {
        "tp_id": "TP_MAT_7_ALJABAR",
        "elemen": "Aljabar",
        "current_p_l": 0.4251,
        "is_mastered": false,
        "last_updated": "2026-05-23T09:15:00Z"
      },
      {
        "tp_id": "TP_MAT_TK_COUNT",
        "elemen": "Bilangan",
        "current_p_l": 0.9850,
        "is_mastered": true,
        "last_updated": "2024-06-12T11:20:00Z"
      }
    ]
  }
}

```

---

### C. Evaluasi Jawaban Adaptif (`POST /api/v1/engine/evaluate`)

Menerima respons jawaban murid, mencatatnya ke log transaksi, memperbarui nilai BKT, dan menentukan materi apa yang harus muncul berikutnya di layar siswa.

#### Request Body:

```json
{
  "tp_id": "TP_MAT_7_ALJABAR",
  "content_item_id": "a4b2c1d0-1234-5678-90ab-cdef12345678",
  "is_correct": false,
  "response_time_seconds": 45
}

```

#### Response (200 OK - Kasus Rerouting / Remedial):

> **CANONICAL**: Field `adaptive_status` mengikuti `GLOSSARY.md` §2.3.

```json
{
  "success": true,
  "message": "Respons dievaluasi oleh Matchmaker Engine.",
  "data": {
    "calculated_p_l": 0.1850,
    "adaptive_status": "REROUTE_TO_PREREQUISITE",
    "target_next_tp_id": "TP_MAT_TK_COUNT",
    "scaffolding_hint": "Jangan berkecil hati! Mari kita segarkan ingatanmu tentang konsep dasar membilang sebelum melanjutkan aljabar ini.",
    "attempt_id": "a1b2c3d4-...",
    "processed_at": "2026-05-23T14:22:10Z"
  }
}

```

**Possible `adaptive_status` values** (lihat GLOSSARY.md §2.3):
* `CONTINUE_PRACTICE` — P(L) antara 0.20–0.85
* `MASTERY_ACHIEVED` — P(L) ≥ 0.85 pada TP primary → unlock ATP berikutnya
* `REROUTE_TO_PREREQUISITE` — P(L) < 0.20 → push prerequisite ke stack
* `REMEDIATION_COMPLETED` — Stack kosong setelah remediation → kembali ke primary
* `SCAFFOLD_REQUIRED` — P(L) < 0.20 tapi tidak ada prerequisite → tutor LLM
* `RETURNING_TO_MAIN` — Sedang naik dari remediation stack

---

### D. Ringkasan Dasbor Analitik Guru (`GET /api/v1/teacher/dashboard/summary`)

Menyediakan data pengelompokan otomatis untuk pembelajaran berdiferensiasi di dalam kelas berdasarkan pembaruan data kognitif terbaru.

#### Query Parameters:

* `class_id` (UUID, Required): ID kelas yang sedang diampu guru saat jam pelajaran tersebut.

#### Response (200 OK):

```json
{
  "success": true,
  "message": "Data analisis kelas berhasil dikompilasi.",
  "data": {
    "class_name": "Kelas 7-A SMP",
    "total_students": 30,
    "differentiation_grouping": {
      "kelompok_fondasi": [
        { "student_id": "9a12b3c4-...", "name": "Rani Wijaya", "last_active_tp": "TP_MAT_7_ALJABAR" }
      ],
      "kelompok_reguler": [
        { "student_id": "8e7d6c5b-...", "name": "Budi Santoso", "last_active_tp": "TP_MAT_7_ALJABAR" }
      ],
      "kelompok_mahir": [
        { "student_id": "1a2b3c4d-...", "name": "Ahmad Dani", "last_active_tp": "TP_MAT_8_FUNGSI" }
      ]
    },
    "system_red_flags": [
      {
        "student_id": "9a12b3c4-...",
        "student_name": "Rani Wijaya",
        "trigger_reason": "Stuck pada materi Aljabar selama 3 sesi beruntun. Indikasi miskonsepsi kronis.",
        "recommended_action": "Berikan bimbingan tatap muka individual menggunakan media kartu peraga bilangan bulat."
      }
    ]
  }
}

```

---

### E. Konten Berikutnya untuk Siswa (`GET /api/v1/student/next-content`)

Dipanggil setelah `MASTERY_ACHIEVED`, `REROUTE_TO_PREREQUISITE`, `REMEDIATION_COMPLETED`, atau cold start. Backend membaca `student_session_state` + `student_current_position` (Doc 03 §3.G–H), lalu mengembalikan ContentItem dari Neo4j.

#### Query Parameters
* `subject_id` (Required): contoh `MATEMATIKA`.

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "content_item_id": "a4b2c1d0-1234-5678-90ab-cdef12345678",
    "content_type": "QUIZ",
    "tp_id": "TP_MAT_6_PERSAMAAN",
    "render_mode": "JUNIOR_ADVENTURE",
    "session_state": "IN_REMEDIATION",
    "remediation_breadcrumb": ["TP_MAT_7_ALJABAR", "TP_MAT_6_PERSAMAAN"],
    "scaffolding_hint": "Ingat: persamaan = dua sisi seimbang.",
    "url_path": "/content/quiz/persamaan_lvl1.json"
  }
}
```

### F. Tutor Chat Streaming (`POST /api/v1/tutor/chat`)

Server-Sent Events (SSE). Hanya untuk role `SISWA`. Detail prompt safety di `09_RAG_AND_TUTOR_SPEC.md` §4.

#### Request Body
```json
{
  "conversation_id": null,
  "context_tp_id": "TP_MAT_7_ALJABAR",
  "message": "Aku belum paham kenapa minus dikali minus jadi plus."
}
```
Jika `conversation_id` null, server membuat baru di `aleta_core.tutor_conversations`.

#### Response (200 OK, `text/event-stream`)
```
event: start
data: {"conversation_id": "9b...", "message_id": 4421}

event: token
data: {"delta": "Bayangkan "}

event: token
data: {"delta": "minus sebagai arah berlawanan…"}

event: end
data: {"finish_reason": "stop", "safety_flags": {}}
```

### G. Briefing Pagi Guru (`GET /api/v1/teacher/morning-briefing`)

#### Query Parameters
* `class_id` (Required)
* `date` (Optional, default = hari ini)

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "class_id": "...",
    "class_name": "Kelas 7-A",
    "session_plan": {
      "subject": "MATEMATIKA",
      "focus_tp_id": "TP_MAT_7_ALJABAR",
      "expected_groups": { "fondasi": 6, "reguler": 18, "mahir": 6 }
    },
    "red_flags": [
      { "student_id": "...", "student_name": "Rani", "reason": "Stuck 3 sesi", "priority": "HIGH" }
    ],
    "ai_recommendations": [
      "Mulai dengan refresher visual 5 menit untuk kelompok fondasi.",
      "Berikan tantangan PJBL untuk kelompok mahir (lihat draft Modul Ajar #...)."
    ],
    "generated_at": "2026-05-23T06:30:00Z"
  }
}
```

### H. Generator Modul Ajar (`POST /api/v1/teacher/modul-ajar/generate`)

#### Request Body
```json
{
  "target_tp_id": "TP_MAT_7_ALJABAR",
  "target_class_id": "9d3...",
  "output_format": "MARKDOWN_STANDARD_MERDEKA",
  "differentiation_levels": ["FONDASI", "REGULER", "MAHIR"]
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "message": "Modul Ajar sedang digenerasi.",
  "data": {
    "draft_id": "f1e2...",
    "status": "GENERATING",
    "poll_url": "/api/v1/teacher/modul-ajar/f1e2..."
  }
}
```

### I. Laporan Anak untuk Orang Tua (`GET /api/v1/parent/child-report`)

#### Query Parameters
* `student_id` (Required) — divalidasi terhadap `student_parent_relations`.
* `period` (Optional ENUM `weekly`, `monthly`, `semester`; default `weekly`).

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "student_id": "...",
    "student_name": "Sandi",
    "period": "weekly",
    "summary": {
      "mastered_this_period": 5,
      "in_progress": 3,
      "struggling": 1
    },
    "headline_insight": "Sandi membuat lompatan di Aljabar minggu ini; konsep operasi bilangan negatif masih perlu latihan.",
    "no_numeric_grade": true,
    "competency_snapshots": [
      { "elemen": "Aljabar", "level": "MAHIR" },
      { "elemen": "Geometri", "level": "REGULER" }
    ]
  }
}
```

### J. Saran Aktivitas Rumah (`GET /api/v1/parent/home-activities`)

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "student_id": "...",
    "anchored_to_tp_id": "TP_MAT_7_ALJABAR",
    "activities": [
      {
        "title": "Hitung Operan Sepak Bola",
        "duration_minutes": 15,
        "materials": ["pena", "kertas"],
        "instruction": "Ajak Sandi menghitung persentase keberhasilan operan saat menonton pertandingan.",
        "interest_match": "SEPAK_BOLA"
      }
    ],
    "generated_at": "2026-05-23T05:00:00Z"
  }
}
```

### K. Consent Request & Decision (`POST /api/v1/consent/request`, `POST /api/v1/consent/{id}/decision`)

#### Request (request endpoint)
```json
{
  "student_id": "...",
  "scope": "EXTERNAL_PSYCHOLOGY",
  "reason": "Penyaringan minat bakat akhir kelas 9 oleh Lembaga Psikologi X.",
  "expires_at": "2026-12-31T23:59:59Z"
}
```

#### Response (201 Created)
```json
{
  "success": true,
  "data": { "consent_id": "...", "status": "PENDING" }
}
```

#### Decision endpoint body
```json
{ "decision": "GRANTED" }
```

> **CANONICAL**: `decision` ∈ {`GRANTED`, `DENIED`} sesuai `consent_decision` enum di GLOSSARY.md §2.2.

Server tulis `decided_at` dengan `decision`, lalu emit `audit_events` dengan `action='CONSENT_GRANTED'` atau `'CONSENT_DENIED'` (Doc 07).

### L. Transisi Lintas Unit (`POST /api/v1/admin/transition`)

Hanya `ADMIN_YAYASAN`. Detil orkestrasi di `12_CROSS_JENJANG_TRANSITION.md`.

#### Request Body
```json
{
  "student_id": "...",
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "effective_date": "2026-07-15"
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "data": {
    "transition_id": "...",
    "status": "SCHEDULED",
    "snapshot_summary": { "mastered_tps": 87, "open_misconceptions": 4 }
  }
}
```

### M. Overview Yayasan (`GET /api/v1/admin/yayasan/overview`)

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "yayasan_name": "Yayasan Bina Cerdas",
    "academic_year": "2025/2026",
    "units": [
      { "tenant_id": "UNIT_TK_01", "active_students": 120, "active_teachers": 12, "avg_mastery_score": 0.72 },
      { "tenant_id": "UNIT_SD_01", "active_students": 540, "active_teachers": 32, "avg_mastery_score": 0.66 }
    ],
    "system_health": {
      "ollama_p95_latency_ms": 1450,
      "evaluate_p95_latency_ms": 220
    }
  }
}
```

---

### N. Parent: List Children + Summary (`GET /api/v1/parent/children`)

> **BARU**: Endpoint untuk Parent App home screen. Lihat PRD Parent App.

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "children": [
      {
        "student_id": "7b8971f4-...",
        "full_name": "Sandi Putra",
        "fase_aktif": "FASE_D",
        "unit_name": "SMP Bina Cerdas",
        "weekly_summary": {
          "mastered_this_week": 5,
          "in_progress": 3,
          "struggling": 1,
          "headline": "Sandi membuat lompatan di Aljabar minggu ini."
        },
        "last_active": "2026-05-23T14:20:00Z"
      }
    ]
  }
}
```

**Validasi**: Server check `student_parent_relations` untuk `parent_id` dari JWT. Return hanya anak yang terhubung.

---

### O. Parent: Weekly Activity Reflection (`GET /api/v1/parent/activity-reflection`)

> **BARU**: Narrative report mingguan untuk Parent App. Generated via LLM dengan fallback template.

#### Query Parameters
* `student_id` (Required) — validated via `student_parent_relations`
* `week_offset` (Optional, default=0) — 0=minggu ini, -1=minggu lalu

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "student_id": "7b8971f4-...",
    "week_start": "2026-05-19",
    "week_end": "2026-05-25",
    "narrative": "Sandi menunjukkan kemajuan konsisten dalam Aljabar. Ia berhasil menguasai konsep persamaan linear minggu ini. Area yang masih perlu perhatian: operasi bilangan negatif. Saran aktivitas: Ajak Sandi menghitung skor pertandingan sepak bola untuk memperkuat konsep negatif/positif.",
    "generated_via": "llm",
    "prompt_version": "parent_headline_v1",
    "competency_highlights": [
      { "elemen": "Aljabar", "progress": "ADVANCED" },
      { "elemen": "Bilangan", "progress": "NEEDS_ATTENTION" }
    ]
  }
}
```

**Fallback**: Jika Ollama unavailable, return template deterministik: "Sandi aktif belajar minggu ini. {mastered_count} materi dikuasai."

---

### P. Admin: Audit Log (`GET /api/v1/admin/audit-log`)

> **BARU**: Akses audit trail. Hanya `ADMIN_YAYASAN` dan `SUPERADMIN`.

#### Query Parameters
* `actor_user_id` (Optional UUID)
* `action` (Optional, e.g., `PASSPORT_ACCESS`, `DATA_EXPORT`)
* `risk_level` (Optional ENUM: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)
* `start_date`, `end_date` (Optional ISO8601)
* `cursor`, `limit` (Pagination)

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "audit_id": "...",
        "actor_user_id": "...",
        "actor_role": "GURU",
        "action": "PASSPORT_ACCESS",
        "target_type": "student",
        "target_id": "7b8971f4-...",
        "tenant_id": "UNIT_SMP_01",
        "ip_address": "192.168.1.42",
        "risk_level": "MEDIUM",
        "reason": "Differentiation dashboard view",
        "created_at": "2026-05-23T14:15:00Z"
      }
    ],
    "next_cursor": "eyJ..."
  }
}
```

---

### Q. Admin: Ops Health (`GET /api/v1/admin/ops-health`)

> **BARU**: Real-time system health untuk Admin Dashboard. Hanya `ADMIN_YAYASAN` dan `SUPERADMIN`.

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "timestamp": "2026-05-23T15:00:00Z",
    "services": {
      "postgres": { "status": "UP", "latency_ms": 12, "connections": 42 },
      "neo4j": { "status": "UP", "latency_ms": 18 },
      "redis": { "status": "UP", "latency_ms": 2, "memory_used_mb": 245 },
      "ollama": { "status": "UP", "model": "llama3:8b-instruct", "gpu_util_pct": 68, "vram_used_mb": 4200, "queue_depth": 3 },
      "qdrant": { "status": "UP", "collections": 2, "vectors": 12450 },
      "keycloak": { "status": "UP", "realm": "aleta" }
    },
    "metrics": {
      "evaluate_p50_ms": 180,
      "evaluate_p95_ms": 420,
      "tutor_p95_ms": 2400,
      "active_sessions": 127,
      "requests_per_minute": 342
    },
    "alerts": [
      { "severity": "WARNING", "message": "Ollama queue depth > 5 for 10 minutes", "since": "2026-05-23T14:50:00Z" }
    ]
  }
}
```

---

### R. Admin: System Config (`GET /api/v1/admin/system-config`, `PUT /api/v1/admin/system-config`)

> **BARU**: Runtime configuration untuk BKT thresholds, LLM prompts, feature flags. Hanya `ADMIN_YAYASAN`.

#### GET Response (200 OK)
```json
{
  "success": true,
  "data": {
    "bkt_mastery_threshold": 0.85,
    "bkt_remedial_threshold": 0.20,
    "llm_tutor_enabled": true,
    "llm_modul_ajar_enabled": true,
    "maintenance_mode": false,
    "config_version": 3,
    "last_updated_by": "admin@yayasan.sch.id",
    "last_updated_at": "2026-05-20T10:00:00Z"
  }
}
```

#### PUT Request Body
```json
{
  "bkt_mastery_threshold": 0.88,
  "reason": "Pilot data menunjukkan false positive mastery di 0.85"
}
```

**Validasi**: Threshold harus antara 0.70–0.95. Setiap perubahan wajib `reason` field dan log ke `audit_events` dengan `action='ADMIN_OPERATION'`.

---

### S. Admin: Bulk Transition (`POST /api/v1/admin/transition/bulk`)

> **BARU**: Batch transition siswa lintas jenjang. Hanya `ADMIN_YAYASAN`.

#### Request Body
```json
{
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "student_ids": ["uuid1", "uuid2", "uuid3"],
  "effective_date": "2026-07-15",
  "reason": "Kenaikan kelas reguler tahun ajaran 2026/2027"
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "data": {
    "batch_id": "batch_...",
    "total_students": 3,
    "status": "SCHEDULED",
    "transitions": [
      { "student_id": "uuid1", "transition_id": "...", "status": "SCHEDULED" }
    ],
    "poll_url": "/api/v1/admin/transition/batch/batch_..."
  }
}
```

**Idempotency**: Wajib `Idempotency-Key` header. Detil orchestration di Doc 12.

---

### T. Notifications (`GET /api/v1/notifications`, `PUT /api/v1/notifications/:id/read`)

> **BARU**: User-facing notifications. Semua role.

#### GET Response (200 OK)
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "notification_id": "...",
        "notification_type": "TUTOR_HANDOFF",
        "title": "Tutor AI butuh bantuan guru",
        "message": "Pertanyaan Sandi tentang aljabar memerlukan penjelasan tatap muka.",
        "action_url": "/teacher/tutor-handoff/conv_...",
        "is_read": false,
        "created_at": "2026-05-23T14:00:00Z"
      }
    ],
    "unread_count": 3
  }
}
```

#### PUT /:id/read Response (204 No Content)

---

## 4. CONTOH KODE IMPLEMENTASI CONTROLLER (FASTAPI / PYTHON)

Gunakan kerangka kode di bawah ini untuk mengimplementasikan kontrak rute evaluasi kuis pada backend berbasis Python Anda.

```python
# backend_core/backend_core/api/engine.py
from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

router = APIRouter(prefix="/api/v1/engine", tags=["AI Engine"])

class KuisEvaluationRequest(BaseModel):
    tp_id: str
    content_item_id: str
    is_correct: bool
    response_time_seconds: int

@router.post("/evaluate")
async def evaluate_student_step(payload: KuisEvaluationRequest, authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Token autentikasi tidak valid atau hilang.")
    
    # [Vibe Coding Note]: Tambahkan fungsi ekstraksi JWT di sini untuk mengambil student_id dan tenant_id
    # student_id = extract_uid_from_jwt(authorization)
    
    # Simulasi interaksi dengan MatchmakerEngine (02_ADAPTIVE_ENGINE_SPEC.md)
    # response_data = matchmaker.evaluate_next_step(...)
    
    return {
        "success": True,
        "message": "Respons dievaluasi oleh Matchmaker Engine.",
        "data": {
            "calculated_p_l": 0.1850,
            "adaptive_status": "REROUTE_TO_PREREQUISITE",  # CANONICAL: lihat GLOSSARY.md §2.3
            "target_next_tp_id": "TP_MAT_TK_COUNT",
            "scaffolding_hint": "Mari kita segarkan ingatanmu tentang konsep dasar membilang.",
            "attempt_id": "a1b2c3d4-...",
            "processed_at": "2026-05-23T14:22:10Z"
        }
    }

```

---
