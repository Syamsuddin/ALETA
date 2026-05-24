-- FILE: seed_mvp_pilot_alpha.sql
-- PURPOSE: Seed data untuk MVP Pilot Alpha ALETA
-- SCOPE: 1 yayasan, 1 unit SMP, 1 kelas, 1 guru, 10 siswa, 5 parent, 5 TP Matematika, 1 rantai prerequisite
-- TARGET: MVP Phase Alpha (10-20 siswa, 1 guru, 1 kelas) sesuai MVP_SCOPE.md §5
-- USAGE: psql -U aleta_user -d aleta_db -f seed_mvp_pilot_alpha.sql
--
-- ⚠️ IMPORTANT: Run this AFTER Alembic migrations (alembic upgrade head) and Neo4j curriculum seed.
-- This seed assumes:
-- - aleta_core schema exists
-- - unit_smp schema exists
-- - Keycloak realm 'aleta' configured with clients
-- - Neo4j has 5 TP nodes with IDs: TP_MAT_7_COUNTING, TP_MAT_7_INTEGER, TP_MAT_7_EQUATION, TP_MAT_7_ALGEBRA_BASIC, TP_MAT_7_ALGEBRA_ADV

-- ============================================================================
-- 1. TENANT (Unit SMP Pilot)
-- ============================================================================

INSERT INTO aleta_core.tenants (tenant_id, name, unit_type, schema_name)
VALUES
    ('UNIT_SMP_PILOT_01', 'SMP Bina Cerdas Pilot', 'SMP', 'unit_smp')
ON CONFLICT (tenant_id) DO NOTHING;

-- ============================================================================
-- 2. USERS (Identitas terpusat di aleta_core.users)
-- ============================================================================

-- 2.1 Admin Yayasan (untuk testing)
INSERT INTO aleta_core.users (user_id, iam_subject, email, role, full_name, is_active)
VALUES
    (gen_random_uuid(), 'keycloak-admin-001', 'admin@pilot.aleta.sch.id', 'ADMIN_YAYASAN', 'Admin Yayasan Pilot', true)
ON CONFLICT (iam_subject) DO NOTHING;

-- 2.2 Guru Matematika
INSERT INTO aleta_core.users (user_id, iam_subject, email, role, full_name, is_active)
VALUES
    (gen_random_uuid(), 'keycloak-guru-mat-001', 'guru.matematika@pilot.aleta.sch.id', 'GURU', 'Ibu Siti Nurhaliza', true)
ON CONFLICT (iam_subject) DO NOTHING;

-- 2.3 Siswa (10 siswa untuk alpha)
INSERT INTO aleta_core.users (user_id, iam_subject, email, role, full_name, is_active)
VALUES
    (gen_random_uuid(), 'keycloak-siswa-001', 'andi.pratama@pilot.aleta.sch.id', 'SISWA', 'Andi Pratama', true),
    (gen_random_uuid(), 'keycloak-siswa-002', 'budi.santoso@pilot.aleta.sch.id', 'SISWA', 'Budi Santoso', true),
    (gen_random_uuid(), 'keycloak-siswa-003', 'citra.dewi@pilot.aleta.sch.id', 'SISWA', 'Citra Dewi', true),
    (gen_random_uuid(), 'keycloak-siswa-004', 'doni.kurniawan@pilot.aleta.sch.id', 'SISWA', 'Doni Kurniawan', true),
    (gen_random_uuid(), 'keycloak-siswa-005', 'eka.putri@pilot.aleta.sch.id', 'SISWA', 'Eka Putri', true),
    (gen_random_uuid(), 'keycloak-siswa-006', 'fajar.ramadhan@pilot.aleta.sch.id', 'SISWA', 'Fajar Ramadhan', true),
    (gen_random_uuid(), 'keycloak-siswa-007', 'gita.sari@pilot.aleta.sch.id', 'SISWA', 'Gita Sari', true),
    (gen_random_uuid(), 'keycloak-siswa-008', 'hadi.wijaya@pilot.aleta.sch.id', 'SISWA', 'Hadi Wijaya', true),
    (gen_random_uuid(), 'keycloak-siswa-009', 'indah.lestari@pilot.aleta.sch.id', 'SISWA', 'Indah Lestari', true),
    (gen_random_uuid(), 'keycloak-siswa-010', 'joko.susanto@pilot.aleta.sch.id', 'SISWA', 'Joko Susanto', true)
ON CONFLICT (iam_subject) DO NOTHING;

-- 2.4 Parent (5 parent untuk 5 siswa pertama)
INSERT INTO aleta_core.users (user_id, iam_subject, email, role, full_name, is_active)
VALUES
    (gen_random_uuid(), 'keycloak-parent-001', 'parent.andi@pilot.aleta.sch.id', 'ORANG_TUA', 'Bapak Pratama', true),
    (gen_random_uuid(), 'keycloak-parent-002', 'parent.budi@pilot.aleta.sch.id', 'ORANG_TUA', 'Ibu Santoso', true),
    (gen_random_uuid(), 'keycloak-parent-003', 'parent.citra@pilot.aleta.sch.id', 'ORANG_TUA', 'Bapak Dewi', true),
    (gen_random_uuid(), 'keycloak-parent-004', 'parent.doni@pilot.aleta.sch.id', 'ORANG_TUA', 'Ibu Kurniawan', true),
    (gen_random_uuid(), 'keycloak-parent-005', 'parent.eka@pilot.aleta.sch.id', 'ORANG_TUA', 'Bapak Putri', true)
ON CONFLICT (iam_subject) DO NOTHING;

-- ============================================================================
-- 3. TENANT SCHEMA (unit_smp) - Classes & Enrollments
-- ============================================================================

-- 3.1 Kelas 7-A
INSERT INTO unit_smp.classes (class_id, class_name, academic_year, homeroom_teacher_id)
SELECT
    gen_random_uuid(),
    'Kelas 7-A',
    '2026/2027',
    u.user_id
FROM aleta_core.users u
WHERE u.iam_subject = 'keycloak-guru-mat-001'
ON CONFLICT DO NOTHING;

-- 3.2 Teaching Assignment (Guru Matematika mengajar Kelas 7-A)
INSERT INTO unit_smp.teaching_assignments (class_id, subject_id, teacher_id, academic_year)
SELECT
    c.class_id,
    'MATEMATIKA',
    u.user_id,
    '2026/2027'
FROM unit_smp.classes c
CROSS JOIN aleta_core.users u
WHERE c.class_name = 'Kelas 7-A'
  AND u.iam_subject = 'keycloak-guru-mat-001'
ON CONFLICT DO NOTHING;

-- 3.3 Enrollment siswa ke kelas
INSERT INTO unit_smp.student_class_enrollment (enrollment_id, student_id, class_id, academic_year, status, enrolled_at)
SELECT
    gen_random_uuid(),
    u.user_id,
    c.class_id,
    '2026/2027',
    'ACTIVE',
    CURRENT_TIMESTAMP
FROM aleta_core.users u
CROSS JOIN unit_smp.classes c
WHERE u.role = 'SISWA'
  AND c.class_name = 'Kelas 7-A'
ON CONFLICT DO NOTHING;

-- 3.4 Parent-Student Relations (5 parent untuk 5 siswa pertama)
INSERT INTO unit_smp.student_parent_relations (student_id, parent_id)
SELECT
    s.user_id AS student_id,
    p.user_id AS parent_id
FROM aleta_core.users s
JOIN aleta_core.users p ON p.iam_subject = CONCAT('keycloak-parent-', LPAD(SPLIT_PART(s.iam_subject, '-', 3), 3, '0'))
WHERE s.role = 'SISWA'
  AND s.iam_subject IN ('keycloak-siswa-001', 'keycloak-siswa-002', 'keycloak-siswa-003', 'keycloak-siswa-004', 'keycloak-siswa-005')
  AND p.role = 'ORANG_TUA'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. COGNITIVE PASSPORT (Inisialisasi P(L) untuk 5 TP per siswa)
-- ============================================================================

-- 5 TP Matematika SMP Kelas 7:
-- 1. TP_MAT_7_COUNTING (prerequisite paling dasar)
-- 2. TP_MAT_7_INTEGER (depends on COUNTING)
-- 3. TP_MAT_7_EQUATION (depends on INTEGER)
-- 4. TP_MAT_7_ALGEBRA_BASIC (depends on EQUATION)
-- 5. TP_MAT_7_ALGEBRA_ADV (depends on ALGEBRA_BASIC)
--
-- Rantai prerequisite: ALGEBRA_ADV → ALGEBRA_BASIC → EQUATION → INTEGER → COUNTING

INSERT INTO aleta_core.student_cognitive_passports (passport_id, student_id, tp_id, current_p_l, is_mastered, last_updated)
SELECT
    gen_random_uuid(),
    u.user_id,
    tp.tp_id,
    0.15,  -- Default p_init sesuai GLOSSARY.md §6
    false,
    CURRENT_TIMESTAMP
FROM aleta_core.users u
CROSS JOIN (
    VALUES
        ('TP_MAT_7_COUNTING'),
        ('TP_MAT_7_INTEGER'),
        ('TP_MAT_7_EQUATION'),
        ('TP_MAT_7_ALGEBRA_BASIC'),
        ('TP_MAT_7_ALGEBRA_ADV')
) AS tp(tp_id)
WHERE u.role = 'SISWA'
ON CONFLICT (student_id, tp_id) DO NOTHING;

-- ============================================================================
-- 5. BKT PARAMS (Kalibrasi default per-TP)
-- ============================================================================

-- Default params untuk 5 TP (sesuai GLOSSARY.md §6 DEFAULT PILOT)
INSERT INTO aleta_core.tp_bkt_params (tp_id, p_init, p_transit, p_guess, p_slip, sample_size, last_calibrated_at)
VALUES
    ('TP_MAT_7_COUNTING', 0.15, 0.20, 0.20, 0.10, 0, NULL),
    ('TP_MAT_7_INTEGER', 0.15, 0.20, 0.20, 0.10, 0, NULL),
    ('TP_MAT_7_EQUATION', 0.15, 0.20, 0.20, 0.10, 0, NULL),
    ('TP_MAT_7_ALGEBRA_BASIC', 0.15, 0.20, 0.20, 0.10, 0, NULL),
    ('TP_MAT_7_ALGEBRA_ADV', 0.15, 0.20, 0.20, 0.10, 0, NULL)
ON CONFLICT (tp_id) DO UPDATE SET
    p_init = EXCLUDED.p_init,
    p_transit = EXCLUDED.p_transit,
    p_guess = EXCLUDED.p_guess,
    p_slip = EXCLUDED.p_slip;

-- ============================================================================
-- 6. STUDENT SESSION STATE (Inisialisasi state machine per siswa)
-- ============================================================================

-- Semua siswa start di NORMAL state, primary TP = COUNTING (awal sequence ATP)
INSERT INTO aleta_core.student_session_state (student_id, subject_id, primary_tp_id, current_tp_id, session_state, remediation_stack, updated_at)
SELECT
    u.user_id,
    'MATEMATIKA',
    'TP_MAT_7_COUNTING',  -- Primary TP (start of ATP sequence)
    'TP_MAT_7_COUNTING',  -- Current TP (sama dengan primary di awal)
    'NORMAL',
    '[]'::jsonb,  -- Empty remediation stack
    CURRENT_TIMESTAMP
FROM aleta_core.users u
WHERE u.role = 'SISWA'
ON CONFLICT (student_id, subject_id) DO NOTHING;

-- ============================================================================
-- 7. SYSTEM CONFIG (Runtime configuration untuk pilot)
-- ============================================================================

-- Config table untuk toggle features dan thresholds
INSERT INTO aleta_core.system_config (config_key, config_value, description, updated_by, updated_at)
VALUES
    ('bkt_mastery_threshold', '0.85', 'Default pilot threshold untuk MASTERY_ACHIEVED (lihat GLOSSARY §6)', 'seed_script', CURRENT_TIMESTAMP),
    ('bkt_remedial_threshold', '0.20', 'Default pilot threshold untuk REROUTE_TO_PREREQUISITE (lihat GLOSSARY §6)', 'seed_script', CURRENT_TIMESTAMP),
    ('llm_tutor_enabled', 'true', 'Enable/disable 24/7 tutor chat (lihat Doc 09 §4.J AI Disabled Mode)', 'seed_script', CURRENT_TIMESTAMP),
    ('llm_modul_ajar_enabled', 'false', 'Enable/disable modul ajar generator (POST-MVP)', 'seed_script', CURRENT_TIMESTAMP),
    ('llm_rewrite_enabled', 'false', 'Enable/disable hobby-aware rewrite (POST-MVP)', 'seed_script', CURRENT_TIMESTAMP),
    ('maintenance_mode', 'false', 'Global maintenance mode flag', 'seed_script', CURRENT_TIMESTAMP)
ON CONFLICT (config_key) DO UPDATE SET
    config_value = EXCLUDED.config_value,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- ============================================================================
-- 8. CONSENT RECORDS (Default opt-in untuk INTERNAL_ASSESSMENT)
-- ============================================================================

-- INTERNAL_ASSESSMENT consent: default GRANTED untuk semua siswa (diperlukan sistem berjalan)
INSERT INTO aleta_core.consent_records (consent_id, student_id, parent_id, scope, decision, decided_at, valid_until)
SELECT
    gen_random_uuid(),
    s.user_id AS student_id,
    p.user_id AS parent_id,
    'INTERNAL_ASSESSMENT',
    'GRANTED',
    CURRENT_TIMESTAMP,
    (CURRENT_TIMESTAMP + INTERVAL '1 year')  -- Valid 1 tahun
FROM aleta_core.users s
JOIN unit_smp.student_parent_relations spr ON spr.student_id = s.user_id
JOIN aleta_core.users p ON p.user_id = spr.parent_id
WHERE s.role = 'SISWA'
  AND p.role = 'ORANG_TUA'
ON CONFLICT (student_id, scope) DO NOTHING;

-- ============================================================================
-- 9. NOTIFICATIONS (Sample notifikasi untuk testing UI)
-- ============================================================================

-- Sample notification untuk 1 siswa (tutor handoff)
INSERT INTO aleta_core.notifications (notification_id, recipient_user_id, notification_type, title, message, action_url, is_read, metadata, created_at)
SELECT
    gen_random_uuid(),
    u.user_id,
    'TUTOR_HANDOFF',
    'Tutor AI butuh bantuan guru',
    'Pertanyaan tentang aljabar perlu penjelasan tatap muka dari guru.',
    '/teacher/tutor-handoff/conv_sample_123',
    false,
    '{"conversation_id": "conv_sample_123", "tp_id": "TP_MAT_7_ALGEBRA_BASIC"}'::jsonb,
    CURRENT_TIMESTAMP
FROM aleta_core.users u
WHERE u.iam_subject = 'keycloak-guru-mat-001'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Sample notification untuk 1 parent (consent request)
INSERT INTO aleta_core.notifications (notification_id, recipient_user_id, notification_type, title, message, action_url, is_read, metadata, created_at)
SELECT
    gen_random_uuid(),
    p.user_id,
    'CONSENT_REQUEST',
    'Permintaan Persetujuan Data',
    'Sekolah meminta persetujuan untuk akses data ekspor laporan.',
    '/parent/consent',
    false,
    '{"consent_scope": "DATA_EXPORT_PARENT"}'::jsonb,
    CURRENT_TIMESTAMP
FROM aleta_core.users p
WHERE p.iam_subject = 'keycloak-parent-001'
LIMIT 1
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 10. AUDIT EVENTS (Sample audit log untuk testing)
-- ============================================================================

-- Sample audit event: admin login
INSERT INTO aleta_core.audit_events (audit_id, actor_user_id, actor_role, tenant_id, action, target_type, target_id, ip_address, risk_level, created_at)
SELECT
    gen_random_uuid(),
    u.user_id,
    'ADMIN_YAYASAN',
    'UNIT_SMP_PILOT_01',
    'LOGIN_SUCCESS',
    'auth',
    NULL,
    '192.168.1.100'::inet,
    'LOW',
    CURRENT_TIMESTAMP
FROM aleta_core.users u
WHERE u.iam_subject = 'keycloak-admin-001'
LIMIT 1;

-- ============================================================================
-- VERIFICATION QUERIES (Run setelah seed untuk verify)
-- ============================================================================

-- Uncomment untuk verify data setelah seed:

-- SELECT COUNT(*) AS total_users FROM aleta_core.users;
-- SELECT COUNT(*) AS total_students FROM aleta_core.users WHERE role = 'SISWA';
-- SELECT COUNT(*) AS total_teachers FROM aleta_core.users WHERE role = 'GURU';
-- SELECT COUNT(*) AS total_parents FROM aleta_core.users WHERE role = 'ORANG_TUA';
-- SELECT COUNT(*) AS total_passports FROM aleta_core.student_cognitive_passports;
-- SELECT COUNT(*) AS total_enrollments FROM unit_smp.student_class_enrollment WHERE status = 'ACTIVE';
-- SELECT COUNT(*) AS total_teaching_assignments FROM unit_smp.teaching_assignments;
-- SELECT config_key, config_value FROM aleta_core.system_config ORDER BY config_key;

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. Neo4j Seed (run separately via Cypher):
--    - Create 5 TP nodes with IDs matching above
--    - Create HAS_PREREQUISITE edges:
--      (:TP {id:'TP_MAT_7_ALGEBRA_ADV'})-[:HAS_PREREQUISITE]->(:TP {id:'TP_MAT_7_ALGEBRA_BASIC'})
--      (:TP {id:'TP_MAT_7_ALGEBRA_BASIC'})-[:HAS_PREREQUISITE]->(:TP {id:'TP_MAT_7_EQUATION'})
--      (:TP {id:'TP_MAT_7_EQUATION'})-[:HAS_PREREQUISITE]->(:TP {id:'TP_MAT_7_INTEGER'})
--      (:TP {id:'TP_MAT_7_INTEGER'})-[:HAS_PREREQUISITE]->(:TP {id:'TP_MAT_7_COUNTING'})
--    - Create ContentItem nodes with TEACHES relationships to each TP
--
-- 2. Keycloak Setup:
--    - Import realm `aleta-realm.json` (Doc 13 §5)
--    - Create users matching iam_subject above
--    - Set temporary passwords
--    - Enable MFA for guru & admin
--
-- 3. Qdrant Collection:
--    - Create collection `aleta_curriculum` with 768-dim vectors (nomic-embed-text)
--    - Ingest curriculum chunks (Doc 09 §3)
--
-- 4. Ollama Models:
--    - docker exec -it aleta_ollama ollama pull llama3:8b-instruct
--    - docker exec -it aleta_ollama ollama pull nomic-embed-text
--
-- ============================================================================
-- END OF SEED FILE
-- ============================================================================
