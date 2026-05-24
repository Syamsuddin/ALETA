# GLOSSARY.md

**Status**: FROZEN (2026-05-24)  
**Purpose**: Canonical reference untuk naming conventions, enums, status codes, dan kontrak data di seluruh blueprint ALETA.

> ⚠️ **CRITICAL**: Dokumen ini adalah single source of truth untuk semua identifier, enum, dan konstanta. Semua blueprint, kode, migration, OpenAPI, dan dokumentasi **WAJIB** mengikuti definisi di sini. Perubahan pada dokumen ini memerlukan review arsitektur.

---

## 1. Database Table Names (Frozen)

### 1.1 Core Schema (`aleta_core`)

| Tabel | Deskripsi | Catatan |
|-------|-----------|---------|
| `users` | Semua identitas pengguna sistem | Single source of identity |
| `tenants` | Daftar unit/jenjang dalam yayasan | Multi-tenancy registry |
| `student_cognitive_passports` | P(L) per-TP lintas jenjang | 12-tahun cognitive record |
| `student_misconceptions` | Log miskonsepsi terdeteksi | Untuk remedial strategy |
| `teaching_assignments` | **CANONICAL**: Relasi guru-kelas-mata pelajaran | ⚠️ Bukan `class_subject_teachers` |
| `student_session_state` | State remediation stack | Survive app close |
| `tp_bkt_params` | Kalibrasi BKT per-TP | p_init, p_transit, p_guess, p_slip |
| `assessment_attempts` | **BARU**: Log jawaban siswa dengan idempotency | Untuk offline queue safety |
| `content_item_versions` | **BARU**: Audit versi soal/video/reading | Untuk historical accuracy |
| `notifications` | **BARU**: Notifikasi untuk tutor handoff, consent | User-facing alerts |
| `audit_events` | Audit trail keamanan | UU PDP compliance |
| `consent_records` | Persetujuan orang tua | GDPR-style consent |
| `system_config` | Runtime configuration | Admin-editable params |

### 1.2 Tenant Schemas (`unit_tk`, `unit_sd`, `unit_smp`, `unit_sma`)

| Tabel | Deskripsi | Catatan |
|-------|-----------|---------|
| `classes` | Kelas per jenjang | Per-tenant transactional |
| `class_enrollments` | Siswa-kelas relations | |
| `student_parent_relations` | Parent-child linkage | Per-unit karena transition |
| `quiz_sessions` | Session kuis siswa | |
| `quiz_logs` | Log jawaban per item | |
| `content_items` | Soal, video, reading per unit | Foreign key ke Neo4j TP |
| `learning_sessions` | Tracking aktivitas siswa | |
| `teacher_modul_requests` | Request modul ajar dari guru | Queue untuk LLM |

---

## 2. Enum Definitions (Frozen)

### 2.1 `user_role` (PostgreSQL ENUM)

```sql
CREATE TYPE user_role AS ENUM (
    'SISWA',
    'GURU',
    'ORANG_TUA',
    'ADMIN_YAYASAN',
    'SUPERADMIN'
);
```

**Tidak ada role lain.** MFA wajib untuk `GURU`, `ADMIN_YAYASAN`, `SUPERADMIN`.

---

### 2.2 `consent_scope` (PostgreSQL ENUM) — **CANONICAL**

```sql
CREATE TYPE consent_scope AS ENUM (
    'INTERNAL_ASSESSMENT',      -- Guru unit sendiri lihat P(L), quiz log, misconception
    'TEACHER_VIEW_CROSS_UNIT',  -- Guru unit lain lihat summary saat transisi
    'EXTERNAL_PSYCHOLOGY',      -- Konselor eksternal akses cognitive passport
    'DATA_EXPORT_PARENT',       -- Orang tua export PDF laporan
    'RESEARCH_ANONYMIZED',      -- Data anonim untuk riset pedagogis yayasan
    'LLM_ENRICHMENT',           -- Hobby-aware rewrite dan tutor personalisasi
    'HOBBY_PROFILING'           -- Sistem simpan profil hobi untuk RAG context
);
```

**Catatan**:
- `INTERNAL_ASSESSMENT`: default opt-in (diperlukan untuk sistem berjalan)
- `TEACHER_VIEW_CROSS_UNIT`: diperlukan saat transisi jenjang
- `EXTERNAL_PSYCHOLOGY`: opt-in eksplisit
- `DATA_EXPORT_PARENT`: opt-in eksplisit, log di `audit_events`
- `RESEARCH_ANONYMIZED`: opt-in, data harus di-anonymize
- `LLM_ENRICHMENT` + `HOBBY_PROFILING`: opt-in, prompt tidak boleh kirim PII

**UI**: Parent App wajib tampilkan consent cards dengan toggle per scope. Keputusan tersimpan di `aleta_core.consent_records` dengan `decided_at`, `decision` (GRANTED/DENIED), `valid_until`.

---

### 2.3 `adaptive_status` (Engine Output) — **CANONICAL**

Status yang dikembalikan `MatchmakerEngine.evaluate()`:

```python
ADAPTIVE_STATUS = Literal[
    "CONTINUE_PRACTICE",        # P(L) antara 0.20–0.85, lanjut latihan
    "MASTERY_ACHIEVED",         # P(L) ≥ 0.85 pada TP primary → unlock ATP berikutnya
    "REROUTE_TO_PREREQUISITE",  # P(L) < 0.20 → push prerequisite ke stack
    "REMEDIATION_COMPLETED",    # Stack kosong setelah remediation → kembali ke primary
    "SCAFFOLD_REQUIRED",        # P(L) < 0.20 tapi tidak ada prerequisite → tutor LLM
    "RETURNING_TO_MAIN"         # Sedang naik dari remediation stack
]
```

**⚠️ Jangan pakai**:
- `MASTERED` (ambiguous, pakai `MASTERY_ACHIEVED`)
- `REMEDIAL_TRIGGERED` (pakai `REROUTE_TO_PREREQUISITE`)
- `IN_PROGRESS` (tidak spesifik)

---

### 2.4 `content_type` (PostgreSQL ENUM)

```sql
CREATE TYPE content_type AS ENUM (
    'VIDEO',
    'READING',
    'INTERACTIVE',
    'QUIZ_ITEM'
);
```

---

### 2.5 `ui_theme_mode` (Frontend)

```typescript
type UiThemeMode = 
    | 'KIDS_GAMIFIED'      // TK–SD kelas 1-2
    | 'JUNIOR_ADVENTURE'   // SD kelas 3-6
    | 'PRO_DASHBOARD';     // SMP, SMA
```

Resolved dari JWT claim `fase_aktif` di Flutter `AuthBloc`.

---

### 2.6 `audit_event_type` (PostgreSQL ENUM)

```sql
CREATE TYPE audit_event_type AS ENUM (
    'LOGIN_SUCCESS',
    'LOGIN_FAILED',
    'PASSPORT_ACCESS',
    'DATA_EXPORT',
    'ROLE_CHANGED',
    'TENANT_CHANGED',
    'CURRICULUM_MODIFIED',
    'CONSENT_GRANTED',
    'CONSENT_REVOKED',
    'ACCOUNT_RESET',
    'ADMIN_OPERATION'
);
```

---

## 3. API Status Codes (Frozen)

### 3.1 HTTP Success

- `200 OK`: GET, PUT berhasil
- `201 Created`: POST resource baru
- `204 No Content`: DELETE berhasil

### 3.2 HTTP Client Error

- `400 Bad Request`: Validasi gagal
- `401 Unauthorized`: Token tidak valid / expired
- `403 Forbidden`: Role tidak cukup / ownership gagal
- `404 Not Found`: Resource tidak ada
- `409 Conflict`: Idempotency key collision, offline conflict
- `422 Unprocessable Entity`: Business logic error
- `429 Too Many Requests`: Rate limit

### 3.3 HTTP Server Error

- `500 Internal Server Error`: Unhandled exception
- `503 Service Unavailable`: Ollama down, Neo4j down

---

## 4. API Error Codes (Application-Level)

Format envelope error:

```json
{
  "error": {
    "code": "PARENT_OWNERSHIP_FAILED",
    "message": "Orang tua tidak memiliki akses ke siswa ini",
    "details": {"student_id": "...", "parent_id": "..."}
  }
}
```

### 4.1 Auth & Authorization

| Code | HTTP | Deskripsi |
|------|------|-----------|
| `INVALID_TOKEN` | 401 | JWT signature/exp/iss invalid |
| `ROLE_INSUFFICIENT` | 403 | Role tidak sesuai endpoint |
| `MFA_REQUIRED` | 403 | User wajib MFA belum setup |
| `TENANT_MISMATCH` | 403 | Tenant di token ≠ tenant di request |

### 4.2 Ownership Violations

| Code | HTTP | Deskripsi |
|------|------|-----------|
| `STUDENT_OWNERSHIP_FAILED` | 403 | Siswa query siswa lain |
| `PARENT_OWNERSHIP_FAILED` | 403 | Parent tidak di `student_parent_relations` |
| `TEACHER_OWNERSHIP_FAILED` | 403 | Guru tidak di `teaching_assignments` untuk kelas ini |

### 4.3 Business Logic

| Code | HTTP | Deskripsi |
|------|------|-----------|
| `CONSENT_ALREADY_DECIDED` | 409 | Consent scope sudah ada keputusan aktif |
| `OFFLINE_CONFLICT` | 409 | Jawaban offline bentrok dengan server state |
| `PREREQUISITE_BROKEN` | 422 | TP tidak punya prerequisite tapi BKT < 0.20 |
| `MODEL_UNAVAILABLE` | 503 | Ollama tidak respon |
| `GRAPH_UNAVAILABLE` | 503 | Neo4j tidak respon |

### 4.4 Data Export

| Code | HTTP | Deskripsi |
|------|------|-----------|
| `EXPORT_CONSENT_REQUIRED` | 403 | Parent belum GRANT `DATA_EXPORT_PARENT` |
| `EXPORT_REASON_REQUIRED` | 400 | Export wajib reason field untuk audit |

---

## 5. API Endpoint Naming (Frozen)

### 5.1 Prefix Pattern

- `/api/v1/auth/*` — Keycloak integration, token refresh
- `/api/v1/engine/*` — Adaptive engine (evaluate, next-content)
- `/api/v1/student/*` — Student-facing resources
- `/api/v1/teacher/*` — Teacher-facing resources
- `/api/v1/parent/*` — Parent-facing resources
- `/api/v1/admin/*` — Admin-facing resources
- `/api/v1/curriculum/*` — Curriculum graph operations

### 5.2 Canonical Endpoints (Subset)

| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/api/v1/engine/evaluate` | SISWA | Submit jawaban + update BKT |
| GET | `/api/v1/engine/next-content` | SISWA | Fetch konten berikutnya |
| GET | `/api/v1/student/passport` | SISWA | Read own cognitive passport |
| GET | `/api/v1/parent/children` | ORANG_TUA | List anak + summary |
| GET | `/api/v1/parent/activity-reflection` | ORANG_TUA | Weekly narrative report |
| POST | `/api/v1/parent/consent` | ORANG_TUA | Grant/deny consent scope |
| GET | `/api/v1/teacher/differentiation` | GURU | Class heatmap P(L) |
| GET | `/api/v1/teacher/red-flags` | GURU | Siswa dengan P(L) < 0.30 |
| POST | `/api/v1/teacher/modul-request` | GURU | Request modul ajar LLM |
| GET | `/api/v1/admin/audit-log` | ADMIN_YAYASAN | Audit events |
| GET | `/api/v1/admin/ops-health` | ADMIN_YAYASAN | System health metrics |
| PUT | `/api/v1/admin/system-config` | ADMIN_YAYASAN | Update runtime config |

**Tidak ada endpoint lain di luar OpenAPI spec.** Client harus generate dari OpenAPI, bukan hardcode.

---

## 6. BKT Threshold (Default Pilot) — **NOT FINAL**

```python
MASTERY_THRESHOLD = 0.85    # P(L) ≥ ini → MASTERY_ACHIEVED
REMEDIAL_THRESHOLD = 0.20   # P(L) < ini → REROUTE_TO_PREREQUISITE

# Default calibration (per TP bisa override via tp_bkt_params)
DEFAULT_P_INIT = 0.15
DEFAULT_P_TRANSIT = 0.20
DEFAULT_P_GUESS = 0.20
DEFAULT_P_SLIP = 0.10
```

**⚠️ Status**: Default pilot. Setelah 3–6 bulan data real, lakukan kalibrasi per-TP menggunakan data `assessment_attempts`. Jangan anggap nilai ini sebagai "final ilmiah".

---

## 7. Neo4j Labels & Relationships (Frozen)

### 7.1 Node Labels

- `:Institution` — Yayasan (node tunggal)
- `:Unit` — TK, SD, SMP, SMA
- `:Fase` — Fondasi, A, B, C, D, E, F
- `:Subject` — Matematika, IPA, Bahasa Indonesia, dll
- `:Elemen` — Grouping CP (dari kurikulum merdeka)
- `:CP` — Capaian Pembelajaran
- `:TP` — Tujuan Pembelajaran (atomic learning goal)
- `:ATP` — Alur Tujuan Pembelajaran (sekuens TP)
- `:ContentItem` — Soal, video, reading
- `:Misconception` — Node miskonsepsi

### 7.2 Relationships

- `[:MANAGES]` — Institution → Unit
- `[:HAS_FASE]` — Unit → Fase
- `[:BELONGS_TO]` — Subject → Fase
- `[:HAS_ELEMEN]` — Subject → Elemen
- `[:DEFINES_CP]` — Elemen → CP
- `[:BREAKS_INTO_TP]` — CP → TP
- `[:HAS_PREREQUISITE]` — **TP → TP** (may cross Fase!)
- `[:PART_OF_ATP]` — TP → ATP
- `[:TEACHES]` — ContentItem → TP
- `[:MAY_TRIGGER]` — TP → Misconception

---

## 8. Offline Queue Contract (Student App)

**Problem**: Siswa jawab kuis offline → sync saat online → risk duplikasi / conflict.

**Solution**: Setiap jawaban offline harus punya:

```dart
class QueuedAnswer {
  final String attemptId;           // UUID client-generated (idempotency key)
  final String studentId;
  final String contentItemId;
  final int contentVersion;         // Versi soal saat dijawab
  final DateTime answeredAt;        // Client timestamp
  final int syncOrder;              // Local sequence number
  final Map<String, dynamic> answer;
}
```

**Server behavior**:
1. Check `assessment_attempts.attempt_id` (unique constraint).
2. Jika sudah ada → return `409 OFFLINE_CONFLICT` dengan server state.
3. Jika `content_version` berbeda → return `422` dengan warning "soal sudah diubah".
4. Jika valid → proses BKT update normal.

**Conflict policy**:
- Client tampilkan dialog: "Jawaban ini sudah pernah dikirim. Server punya skor X. Hapus dari queue?"
- User bisa pilih: **Keep local** (override) atau **Discard** (buang).

---

## 9. Design Token Enforcement (Strict)

**Rule**: **ZERO warna hardcoded di production code.**

### ❌ Dilarang:

```tsx
<div className="bg-amber-50 text-red-600">...</div>  // Tailwind arbitrary
<Box sx={{ backgroundColor: '#FEF3C7' }}>...</Box>   // Hex hardcoded
```

### ✅ Wajib:

```tsx
<div className="bg-surface-warning text-content-error">...</div>
<Box sx={{ backgroundColor: 'var(--color-surface-warning)' }}>...</Box>
```

**Enforcement**:
- ESLint rule: `no-hardcoded-colors` (ban `#`, `rgb()`, Tailwind color tanpa semantic alias)
- CI gate: linter error → block PR

**Semantic color tokens** (dari `14_UI_UX_DESIGN_SYSTEM.md` design-tokens.json):
- `--color-primary-*`
- `--color-surface-*` (default, elevated, warning, error, success)
- `--color-content-*` (primary, secondary, tertiary, error, success)

---

## 10. LLM Prompt Versioning

Setiap LLM call harus log `prompt_version` untuk auditability.

**Format**: `<use_case>_<variant>_v<number>`

Contoh:
- `tutor_system_v1` — System prompt untuk 24/7 tutor
- `modul_ajar_scaffold_v2` — Prompt untuk modul ajar generator
- `hobby_rewrite_v1` — Hobby-aware content rewrite
- `parent_headline_v1` — Weekly narrative untuk parent report

**Storage**: Simpan di tabel `system_config` dengan key `llm_prompt_<name>`, atau di file `prompts/<name>.txt` (version controlled).

**Logging**: Setiap response LLM wajib punya field `prompt_version` di metadata untuk debugging.

---

## 11. Naming Conventions per Language

### 11.1 PostgreSQL

- **Schema**: `lowercase_snake` (`aleta_core`, `unit_smp`)
- **Table**: `lowercase_snake` (`student_cognitive_passports`, `teaching_assignments`)
- **Column**: `lowercase_snake` (`student_id`, `is_mastered`, `created_at`)
- **Enum type**: `lowercase_snake` (`user_role`, `consent_scope`)
- **Enum value**: `UPPERCASE_SNAKE` (`SISWA`, `INTERNAL_ASSESSMENT`)

### 11.2 Python (FastAPI, AI Engine)

- **Module**: `lowercase_snake` (`bkt_engine.py`, `matchmaker.py`)
- **Class**: `PascalCase` (`ALETA_BKT_Engine`, `MatchmakerEngine`)
- **Function**: `lowercase_snake` (`update_knowledge_state()`, `evaluate()`)
- **Constant**: `UPPERCASE_SNAKE` (`MASTERY_THRESHOLD`, `DEFAULT_P_INIT`)
- **Variable**: `lowercase_snake` (`current_p_l`, `remediation_stack`)

### 11.3 Dart (Flutter)

- **File**: `lowercase_snake` (`auth_bloc.dart`, `passport_repository.dart`)
- **Class**: `PascalCase` (`AuthBloc`, `PassportRepository`, `QuizState`)
- **Method**: `camelCase` (`fetchPassport()`, `submitAnswer()`)
- **Variable**: `camelCase` (`currentStudent`, `isLoading`)
- **Constant**: `lowerCamelCase` (`kDefaultPadding`, `kPrimaryColor`)

### 11.4 TypeScript/React

- **File**: `PascalCase` untuk component (`DifferentiationHeatmap.tsx`), `camelCase` untuk utils (`apiClient.ts`)
- **Component**: `PascalCase` (`DifferentiationHeatmap`, `RedFlagList`)
- **Function**: `camelCase` (`fetchDifferentiation()`, `handleExport()`)
- **Variable**: `camelCase` (`studentData`, `isLoading`)
- **Constant**: `UPPERCASE_SNAKE` (`API_BASE_URL`, `MAX_RETRIES`)

### 11.5 Docker & Services

- **Container**: `aleta_<service>` (`aleta_core_api`, `aleta_ollama`, `aleta_keycloak`)
- **Network**: `aleta_network`
- **Volume**: `aleta_<data>` (`aleta_postgres_data`, `aleta_neo4j_data`)

---

## 12. Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-05-24 | Initial freeze based on blueprint review | Claude Code |

---

## 13. Compliance Checklist

Sebelum merge PR atau migration baru:

- [ ] Semua enum value ada di GLOSSARY.md?
- [ ] Semua tabel baru sudah terdaftar di §1?
- [ ] Endpoint baru sudah di OpenAPI spec?
- [ ] Error code baru sudah di §4?
- [ ] Naming convention diikuti per language?
- [ ] Tidak ada warna hardcoded di React/Flutter?
- [ ] LLM call punya `prompt_version`?
- [ ] Offline queue jawaban pakai `attempt_id`?

**Jika jawaban ada yang "tidak"**, PR ditolak sampai GLOSSARY.md diperbarui terlebih dahulu.

---

**END OF GLOSSARY.md**
