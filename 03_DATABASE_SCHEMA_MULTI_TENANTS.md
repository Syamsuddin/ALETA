---
doc: "03"
title: "Database Schema Multi-Tenants"
scope: "PostgreSQL aleta_core + unit_* schemas, RLS policies, trigger check_tp_mastery, multi-tenancy SET LOCAL pattern"
key_entities: [aleta_core, unit_smp, student_cognitive_passports, audit_events, tenants, tp_bkt_params, teaching_assignments, assessment_attempts, content_item_versions, notifications, consent_records]
depends_on: ["01", "GLOSSARY"]
loaded_by_tasks: [T-101, T-102, T-105]
canonical_reference: "GLOSSARY.md untuk semua enum, table names, naming conventions"
---

# FILE: 03_DATABASE_SCHEMA_MULTI_TENANTS.md
# PROJECT ALETA: MULTI-TENANT DATABASE SCHEMA SPECIFICATION (POSTGRESQL)

> ⚠️ **CANONICAL REFERENCE**: Semua nama tabel, enum, dan konstanta di dokumen ini WAJIB mengikuti `GLOSSARY.md` (frozen 2026-05-24). Jika ada inkonsistensi, GLOSSARY menang.

## 1. PENDAHULUAN & STRATEGI MULTI-TENANCY
Dokumen ini menetapkan spesifikasi skema basis data relasional menggunakan PostgreSQL untuk Project ALETA lingkup Yayasan. 

Untuk mengoptimalkan efisiensi biaya sewa *cloud* Yayasan tanpa mengorbankan keamanan data, ALETA menggunakan strategi **Multi-Tenancy via PostgreSQL Schemas**. 
*   **Core Schema (`aleta_core`):** Menyimpan data master organisasi global, akun pengguna terpusat, dan tabel paspor kognitif lintas jenjang.
*   **Tenant Schemas (`unit_tk`, `unit_sd`, `unit_smp`, `unit_sma`):** Skema terisolasi untuk masing-masing unit sekolah guna menyimpan data transaksi harian kelas, presensi, kuis, dan rapor internal unit.

---

## 2. SKEMA DATABASES UTAMA (`aleta_core`)
Tabel-tabel di bawah ini berada di bawah skema global `aleta_core` dan bertindak sebagai jangkar identitas data 12 tahun siswa.

### A. Tabel: `tenants` (Unit Sekolah)
Menyimpan data pendaftaran unit sekolah di bawah yayasan.
```sql
CREATE TABLE aleta_core.tenants (
    tenant_id VARCHAR(50) PRIMARY KEY, -- e.g., 'UNIT_TK_01', 'UNIT_SMA_01'
    name VARCHAR(100) NOT NULL,
    unit_type VARCHAR(10) CHECK (unit_type IN ('TK', 'SD', 'SMP', 'SMA', 'SMK')),
    schema_name VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'unit_tk', 'unit_sma'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

```

### B. Tabel: `users` (Master Profil Terpusat via Keycloak SSO)

Setiap manusia dalam organisasi (Siswa, Guru, Ortu, Admin) hanya memiliki 1 baris profil di tabel ini seumur hidup. Kredensial dan password hash tidak disimpan di database aplikasi; ALETA menyimpan `iam_subject` dari Keycloak sebagai referensi identitas tunggal.

```sql
CREATE TYPE user_role AS ENUM ('SUPERADMIN', 'ADMIN_YAYASAN', 'GURU', 'SISWA', 'ORANG_TUA');

CREATE TABLE aleta_core.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iam_subject VARCHAR(100) UNIQUE NOT NULL, -- ID sub dari Keycloak
    email VARCHAR(100) UNIQUE NOT NULL,
    role user_role NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

```

### C. Tabel: `student_cognitive_passports` (Benang Merah 12 Tahun)

Tabel terpenting yang dibaca oleh *Matchmaker Engine* Python untuk melacak probabilitas penguasaan materi ($P(L)$) kumulatif secara langsung.

```sql
CREATE TABLE aleta_core.student_cognitive_passports (
    passport_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    tp_id VARCHAR(50) NOT NULL, -- Terhubung dengan Node ID di Neo4j
    current_p_l NUMERIC(5,4) NOT NULL DEFAULT 0.1500, -- Nilai P(L) dari BKT Engine
    is_mastered BOOLEAN DEFAULT FALSE, -- TRUE jika current_p_l >= 0.85
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_student_tp UNIQUE (student_id, tp_id)
);

-- Indexing untuk pembacaan instan oleh AI Recommender
CREATE INDEX idx_passport_lookup ON aleta_core.student_cognitive_passports (student_id, is_mastered);

```

### D-pra. Tooling Migrasi
Skema-skema di bawah ini wajib di-version-control menggunakan **Alembic** (`backend_core/alembic/`). Lihat `13_MIGRATIONS_AND_CICD.md` §2 untuk struktur folder dan command `alembic upgrade head`.

### D. Tabel: `student_affective_profiles` (Lensa Minat Bakat)

Menyimpan preferensi gaya belajar dan hobi siswa yang diekstrak secara berkala oleh AI untuk kebutuhan injeksi konteks soal (*RAG Prompting*).

```sql
CREATE TABLE aleta_core.student_affective_profiles (
    student_id UUID PRIMARY KEY REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    dominant_learning_style VARCHAR(20) DEFAULT 'VISUAL' CHECK (dominant_learning_style IN ('VISUAL', 'AUDIO', 'TEXT', 'KINESTHETIC')),
    primary_interest VARCHAR(50) DEFAULT 'UMUM', -- legacy single interest
    interest_vector JSONB DEFAULT '[]'::jsonb,    -- [{"tag":"SEPAK_BOLA","weight":0.7,"updated_at":"..."}]
    ai_calculated_focus_score NUMERIC(3,2) DEFAULT 1.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

```

Algoritma update `ai_calculated_focus_score` dan `interest_vector` didefinisikan di `09_RAG_AND_TUTOR_SPEC.md` §3.

### E. Tabel: `student_misconceptions` (Peta Miskonsepsi Lintas Tahun)

Pasangan node `Misconception` dari Neo4j (Doc 01 §2.I). Setiap deteksi miskonsepsi pada `MatchmakerEngine.evaluate()` menambah baris di sini.

```sql
CREATE TABLE aleta_core.student_misconceptions (
    record_id BIGSERIAL PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    misconception_id VARCHAR(60) NOT NULL,        -- mirror dari node Neo4j
    triggered_on_tp_id VARCHAR(50) NOT NULL,
    occurrence_count INTEGER NOT NULL DEFAULT 1,
    first_detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_student_misconception UNIQUE (student_id, misconception_id, triggered_on_tp_id)
);

CREATE INDEX idx_misconception_lookup ON aleta_core.student_misconceptions (student_id, resolved_at);
```

### F. Tabel: `tp_bkt_params` (Parameter BKT Per-TP Hasil Kalibrasi)

Disimpan global karena TP itu sendiri global (Neo4j). Job kalibrasi nightly (Doc 02 §6) menulis ke tabel ini.

```sql
CREATE TABLE aleta_core.tp_bkt_params (
    tp_id VARCHAR(50) PRIMARY KEY,
    p_init NUMERIC(5,4) NOT NULL DEFAULT 0.1500,
    p_transit NUMERIC(5,4) NOT NULL DEFAULT 0.2000,
    p_guess NUMERIC(5,4) NOT NULL DEFAULT 0.2000,
    p_slip NUMERIC(5,4) NOT NULL DEFAULT 0.1000,
    sample_size INTEGER NOT NULL DEFAULT 0,
    last_calibrated_at TIMESTAMP WITH TIME ZONE,
    CHECK (p_guess <= 0.30 AND p_slip <= 0.10 AND p_transit BETWEEN 0.05 AND 0.40)
);
```

### G. Tabel: `student_session_state` (Persist State Machine Remedial)

Dipersist supaya state remediation tidak hilang ketika aplikasi siswa ditutup.

```sql
CREATE TABLE aleta_core.student_session_state (
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    subject_id VARCHAR(50) NOT NULL,
    primary_tp_id VARCHAR(50) NOT NULL,
    current_tp_id VARCHAR(50) NOT NULL,
    session_state VARCHAR(30) NOT NULL DEFAULT 'NORMAL'
        CHECK (session_state IN ('NORMAL', 'IN_REMEDIATION', 'RETURNING_TO_MAIN')),
    remediation_stack JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, subject_id)
);
```

### H. Tabel: `student_current_position` (Cursor ATP Aktif)

```sql
CREATE TABLE aleta_core.student_current_position (
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    subject_id VARCHAR(50) NOT NULL,
    atp_sequence_id UUID NOT NULL,                -- mirror Neo4j ATPSequence.id
    current_tp_id VARCHAR(50) NOT NULL,
    position_index INTEGER NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, subject_id)
);
```

### I. Tabel: `consent_records` (Persetujuan UU PDP)

> **CANONICAL**: Lihat `GLOSSARY.md` §2.2 untuk definisi `consent_scope` yang di-freeze.

```sql
-- Enum consent_scope: CANONICAL di GLOSSARY.md §2.2
CREATE TYPE consent_scope AS ENUM (
    'INTERNAL_ASSESSMENT',      -- Guru unit sendiri lihat P(L), quiz log, misconception
    'TEACHER_VIEW_CROSS_UNIT',  -- Guru unit lain lihat summary saat transisi
    'EXTERNAL_PSYCHOLOGY',      -- Konselor eksternal akses cognitive passport
    'DATA_EXPORT_PARENT',       -- Orang tua export PDF laporan
    'RESEARCH_ANONYMIZED',      -- Data anonim untuk riset pedagogis yayasan
    'LLM_ENRICHMENT',           -- Hobby-aware rewrite dan tutor personalisasi
    'HOBBY_PROFILING'           -- Sistem simpan profil hobi untuk RAG context
);

CREATE TYPE consent_decision AS ENUM ('GRANTED', 'DENIED');

CREATE TABLE aleta_core.consent_records (
    consent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    scope consent_scope NOT NULL,
    decision consent_decision NOT NULL,
    decided_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    request_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_active_consent UNIQUE (student_id, scope)
);

CREATE INDEX idx_consent_active ON aleta_core.consent_records (student_id, scope, decision);
```

**Catatan UX**: Parent App wajib tampilkan consent card per scope dengan toggle. `INTERNAL_ASSESSMENT` adalah opt-in default (diperlukan sistem berjalan). `DATA_EXPORT_PARENT` wajib log di `audit_events`.

### I-a. Tabel: `assessment_attempts` (Idempotency Jawaban Siswa)

> **BARU**: Mengatasi risiko duplikasi jawaban offline. Lihat `GLOSSARY.md` §8 untuk contract offline queue.

```sql
CREATE TABLE aleta_core.assessment_attempts (
    attempt_id UUID PRIMARY KEY,                    -- Client-generated (idempotency key)
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    content_item_id UUID NOT NULL,                  -- Referensi soal/quiz
    content_version INTEGER NOT NULL DEFAULT 1,     -- Versi soal saat dijawab
    tp_id VARCHAR(50) NOT NULL,
    answer_payload JSONB NOT NULL,                  -- {selected_option, free_text, etc}
    is_correct BOOLEAN NOT NULL,
    response_time_seconds INTEGER,
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL,  -- Client timestamp
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_order INTEGER,                             -- Client sequence untuk offline batch
    CONSTRAINT unique_attempt UNIQUE (attempt_id)
);

CREATE INDEX idx_attempt_student_tp ON aleta_core.assessment_attempts (student_id, tp_id, processed_at DESC);
CREATE INDEX idx_attempt_content ON aleta_core.assessment_attempts (content_item_id, content_version);
```

**Offline Queue Safety**:

* Client generate `attempt_id` (UUID v4) sebelum submit.
* Server check unique constraint. Jika sudah ada → return `409 OFFLINE_CONFLICT`.
* Jika `content_version` berbeda → return `422` (soal sudah diubah sejak offline).

---

### I-b. Tabel: `content_item_versions` (Audit Versi Konten)

> **BARU**: Tracking perubahan soal, video, reading untuk historical accuracy.

```sql
CREATE TABLE aleta_core.content_item_versions (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_item_id UUID NOT NULL,                  -- Referensi ContentItem di Neo4j atau PostgreSQL
    version_number INTEGER NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('VIDEO', 'READING', 'INTERACTIVE', 'QUIZ_ITEM')),
    content_payload JSONB NOT NULL,                 -- {question_text, options, video_url, etc}
    difficulty_level NUMERIC(3,2),
    changed_by UUID REFERENCES aleta_core.users(user_id),
    change_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_content_version UNIQUE (content_item_id, version_number)
);

CREATE INDEX idx_content_version_lookup ON aleta_core.content_item_versions (content_item_id, version_number DESC);
```

**Use Case**: Saat siswa jawab soal offline, simpan `content_version`. Saat sync, server bisa validasi apakah soal sudah berubah sejak dijawab.

---

### I-c. Tabel: `notifications` (User-Facing Alerts)

> **BARU**: Notifikasi untuk tutor handoff, consent request, transition alert, system announcement.

```sql
CREATE TYPE notification_type AS ENUM (
    'TUTOR_HANDOFF',            -- Tutor AI tidak bisa jawab, butuh guru
    'CONSENT_REQUEST',          -- Permintaan consent baru dari admin/guru
    'TRANSITION_ALERT',         -- Pemberitahuan transisi jenjang
    'SYSTEM_ANNOUNCEMENT',      -- Pengumuman yayasan
    'ACHIEVEMENT_UNLOCK'        -- Gamification: TP mastered milestone
);

CREATE TABLE aleta_core.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    notification_type notification_type NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(200),                        -- Deep link ke halaman terkait
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,             -- {conversation_id, tp_id, etc}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_notification_recipient ON aleta_core.notifications (recipient_user_id, is_read, created_at DESC);
```

**Endpoint**: `GET /api/v1/notifications` (semua role), `PUT /api/v1/notifications/:id/read`.

---

### J. Tabel: `student_transition_events` (Migrasi Antar Unit)

Direkam saat siswa lulus dari satu unit ke unit lain dalam Yayasan yang sama. Detil orkestrasi di `12_CROSS_JENJANG_TRANSITION.md`.

```sql
CREATE TYPE transition_status AS ENUM ('SCHEDULED', 'EXECUTING', 'COMPLETED', 'FAILED', 'ROLLED_BACK');

CREATE TABLE aleta_core.student_transition_events (
    transition_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    from_tenant_id VARCHAR(50) NOT NULL REFERENCES aleta_core.tenants(tenant_id),
    to_tenant_id VARCHAR(50) NOT NULL REFERENCES aleta_core.tenants(tenant_id),
    from_fase VARCHAR(20) NOT NULL,
    to_fase VARCHAR(20) NOT NULL,
    initiated_by UUID NOT NULL REFERENCES aleta_core.users(user_id),
    status transition_status NOT NULL DEFAULT 'SCHEDULED',
    snapshot_summary JSONB,                       -- ringkasan TP mastered untuk audit
    executed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (from_tenant_id <> to_tenant_id)
);

CREATE INDEX idx_transition_student ON aleta_core.student_transition_events (student_id, created_at DESC);
```

### K. Tabel: `tutor_conversations` & `tutor_messages` (Chatbot 24/7)

Dipakai oleh `POST /api/v1/tutor/chat` di Doc 04. Detil prompt safety di `09_RAG_AND_TUTOR_SPEC.md`.

```sql
CREATE TABLE aleta_core.tutor_conversations (
    conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    context_tp_id VARCHAR(50),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE aleta_core.tutor_messages (
    message_id BIGSERIAL PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES aleta_core.tutor_conversations(conversation_id) ON DELETE CASCADE,
    role VARCHAR(10) NOT NULL CHECK (role IN ('SYSTEM','USER','ASSISTANT')),
    content TEXT NOT NULL,
    redacted BOOLEAN NOT NULL DEFAULT FALSE,
    safety_flags JSONB DEFAULT '{}'::jsonb,
    token_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tutor_msg_conv ON aleta_core.tutor_messages (conversation_id, created_at);
```

### L. Tabel: `modul_ajar_drafts` (Generator Modul Ajar Guru)

```sql
CREATE TABLE aleta_core.modul_ajar_drafts (
    draft_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    tenant_id VARCHAR(50) NOT NULL REFERENCES aleta_core.tenants(tenant_id),
    target_class_id UUID NOT NULL,
    target_tp_id VARCHAR(50) NOT NULL,
    output_format VARCHAR(40) NOT NULL DEFAULT 'MARKDOWN_STANDARD_MERDEKA',
    status VARCHAR(20) NOT NULL DEFAULT 'GENERATING'
        CHECK (status IN ('GENERATING', 'READY', 'REJECTED', 'PUBLISHED')),
    content_markdown TEXT,
    llm_model VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    finalized_at TIMESTAMP WITH TIME ZONE
);
```

### M. Tabel: `audit_events` (canonical placement)

Spesifikasi kolom didefinisikan di `07_SECURITY_PRIVACY_PASSPORT.md` §F. Tabel ini **fisiknya** dibuat oleh migrasi Doc 03 ini (bukan Doc 07) — Doc 07 hanya menetapkan kebijakan event yang wajib di-audit.

```sql
CREATE TABLE aleta_core.audit_events (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES aleta_core.users(user_id),
    actor_role user_role NOT NULL,
    tenant_id VARCHAR(50),
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    reason TEXT,
    risk_level VARCHAR(20) DEFAULT 'LOW' CHECK (risk_level IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_actor_time ON aleta_core.audit_events (actor_user_id, created_at DESC);
CREATE INDEX idx_audit_action ON aleta_core.audit_events (action, created_at DESC);
```

---

## 3. CONTOH SKEMA PENYEDERHANAAN TENANT (`unit_smp`)

Skema di bawah ini dibentuk dinamis atau via migrasi untuk unit tertentu (Contoh: `unit_smp`). Struktur tabel di dalam skema ini terisolasi dari skema unit lain.

```sql
CREATE SCHEMA IF NOT EXISTS unit_smp;

-- Tabel Relasi Orang Tua dan Anak (Spesifik per unit sekolah untuk kemudahan mutasi)
CREATE TABLE unit_smp.student_parent_relations (
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    parent_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    PRIMARY KEY (student_id, parent_id)
);

-- Tabel Transaksi Kelas Harian
CREATE TABLE unit_smp.classes (
    class_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_name VARCHAR(50) NOT NULL, -- e.g., 'Kelas 7-A'
    academic_year VARCHAR(20) NOT NULL, -- e.g., '2025/2026'
    homeroom_teacher_id UUID REFERENCES aleta_core.users(user_id)
);

-- Enrolment siswa ↔ kelas (banyak-ke-banyak per tahun ajaran)
CREATE TABLE unit_smp.student_class_enrollment (
    enrollment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES unit_smp.classes(class_id) ON DELETE CASCADE,
    academic_year VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'TRANSFERRED', 'GRADUATED', 'WITHDRAWN')),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_active_enrollment UNIQUE (student_id, class_id, academic_year)
);

CREATE INDEX idx_enrollment_class ON unit_smp.student_class_enrollment (class_id, status);
CREATE INDEX idx_enrollment_student ON unit_smp.student_class_enrollment (student_id, status);

-- Pengajar mata pelajaran per kelas (banyak guru bisa mengajar satu kelas)
-- CANONICAL NAME: teaching_assignments (lihat GLOSSARY.md §1.1)
CREATE TABLE unit_smp.teaching_assignments (
    class_id UUID NOT NULL REFERENCES unit_smp.classes(class_id) ON DELETE CASCADE,
    subject_id VARCHAR(50) NOT NULL,
    teacher_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    academic_year VARCHAR(20) NOT NULL,
    PRIMARY KEY (class_id, subject_id, academic_year)
);

-- Tabel Log Resonansi Jawaban Kuis (Data mentah umpan balik untuk BKT Engine)
CREATE TABLE unit_smp.student_quiz_logs (
    log_id BIGSERIAL PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES aleta_core.users(user_id),
    tp_id VARCHAR(50) NOT NULL,
    content_item_id UUID NOT NULL, -- Referensi material/soal dari Neo4j
    is_correct BOOLEAN NOT NULL,
    response_time_seconds INT NOT NULL, -- Berapa detik murid memikirkan soal ini
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_quiz_logs_student ON unit_smp.student_quiz_logs (student_id, tp_id);

```

---

## 4. QUERY LOGIKA MULTI-TENANCY UNTUK VIBE CODING (BACKEND REPO)

Saat menulis kode backend FastAPI, koneksi database dapat diarahkan ke skema yang dinamis menggunakan perintah SQL `SET LOCAL search_path` di dalam transaksi request. Pola lengkap tenant isolation, RLS claim setting, whitelist schema, dan audit event wajib mengikuti `07_SECURITY_PRIVACY_PASSPORT.md`.

### A. Logika Route Handler: Mengubah Cakupan Tenant Secara Dinamis

```sql
-- Ketika request Guru SMP valid, Backend mengeksekusi ini di dalam transaksi request:
BEGIN;
SET LOCAL search_path TO unit_smp, aleta_core;
SET LOCAL request.jwt.claim.sub = 'USER_UUID_FROM_TOKEN';
SET LOCAL request.jwt.claim.role = 'GURU';

-- Query berikutnya otomatis membaca tabel milik SMP tanpa perlu join manual lintas database:
SELECT c.class_name, u.full_name AS wali_kelas 
FROM classes c
JOIN aleta_core.users u ON c.homeroom_teacher_id = u.user_id;

COMMIT;

```

### B. Trigger Otomatis: Sinkronisasi Status Kelulusan Materi (Mastery)

Fungsi pemicu (*Database Trigger*) ini otomatis mengubah bendera `is_mastered` menjadi `TRUE` jika *BKT Engine* memperbarui skor kognitif siswa melewati angka `0.8500`.

```sql
CREATE OR REPLACE FUNCTION aleta_core.check_tp_mastery()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_p_l >= 0.8500 THEN
        NEW.is_mastered := TRUE;
    ELSE
        NEW.is_mastered := FALSE;
    END IF;
    NEW.last_updated := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_tp_mastery
    BEFORE INSERT OR UPDATE ON aleta_core.student_cognitive_passports
    FOR EACH ROW
    EXECUTE FUNCTION aleta_core.check_tp_mastery();

```

---

## 5. SKEMA MIGRASI INISIALISASI (UP SCRIPT)

Gunakan blok kode SQL di bawah ini untuk menginisialisasi arsitektur database awal dalam kontainer PostgreSQL Anda:

```sql
DO $$ 
BEGIN
    -- 1. Buat Schema Core
    CREATE SCHEMA IF NOT EXISTS aleta_core;
    
    -- 2. Jalankan pembuatan ekstensi UUID jika belum ada
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    
    -- 3. Cetak log sukses
    RAISE NOTICE 'Skema inti ALETA berhasil diinisialisasi.';
END $$;

```

---
