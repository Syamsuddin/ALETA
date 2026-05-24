# MVP_SCOPE.md

**Status**: FROZEN (2026-05-24)  
**Purpose**: Definisi scope pilot MVP Phase 1 ALETA — irisan kecil end-to-end untuk validasi produk.

> ⚠️ **CRITICAL**: Jangan implement full blueprint sekaligus. MVP adalah irisan minimal yang **end-to-end functional** untuk membuktikan value proposition core: adaptive learning + cognitive passport + 24/7 tutor.

---

## 1. FILOSOFI MVP

MVP ALETA bukan "semua fitur tapi setengah jadi". MVP adalah **subset fitur yang saling terkait, fully functional, production-ready untuk cohort kecil**.

**Prinsip**:
* **End-to-end**, bukan horizontal slice. Siswa harus bisa: login → quiz → BKT update → remediation → tutor → parent report.
* **Single happy path**, bukan semua edge case. Fokus golden path Matematika SMP.
* **Real data**, bukan mock/demo. Gunakan 1 kelas real dengan 10–20 siswa real.
* **Measurable**, bukan "proof of concept". Setelah 4–8 minggu, kita harus bisa ukur: engagement rate, mastery velocity, tutor handoff rate, parent satisfaction.

---

## 2. SCOPE MVP PHASE 1

### A. Pilot Cohort

| Dimension | MVP Scope | Rationale |
| :--- | :--- | :--- |
| **Unit Sekolah** | 1 (SMP) | Multi-unit complexity ditunda. Fokus validasi adaptive loop dulu. |
| **Siswa Aktif** | 10–20 (alpha), 50–100 (beta), 200 (production pilot) | Cukup untuk detect pattern, tidak overload GPU. |
| **Guru Aktif** | 1 (alpha), 3 (beta), 10 (production) | 1 guru Matematika untuk alpha; 3 guru (Mat, IPA, B.Ind) untuk beta. |
| **Parent Aktif** | 20–40 | Validasi parent report & consent UX. |
| **Mata Pelajaran** | 1 (Matematika) | Expand ke IPA/B.Ind di beta. |
| **Fase** | FASE_D (SMP Kelas 7–9) | Tidak perlu 3 mode UI (Kids/Junior/Pro) — hanya Pro Dashboard. |
| **TP Count** | 50 (alpha), 200 (beta), 500 (production) | Matematika SMP Grade 7: ~50 TP (Aljabar, Bilangan, Geometri dasar). |
| **ATP Sequence** | 1 linear sequence | Tidak perlu branching/adaptive ATP. Sequence linear sudah cukup. |
| **Prerequisite Chain** | 1 rantai (5–10 TP) | Contoh: TP Aljabar → TP Persamaan → TP Bilangan Bulat → TP Counting. |
| **ContentItem** | 200–500 quiz items | ~4–10 soal per TP (varied difficulty). |

### B. Fitur Student App (Flutter)

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Login & Auth** | ✅ Keycloak OIDC, JWT, MFA untuk guru/admin | — |
| **Home Dashboard** | ✅ PRO_DASHBOARD mode only (FASE_D) | Kids/Junior mode |
| **Quiz Player** | ✅ Multiple choice + numeric, BKT update, adaptive_status response | Essay/drag-drop question types |
| **Remediation Flow** | ✅ `REROUTE_TO_PREREQUISITE`, `RETURNING_TO_MAIN`, breadcrumb UI | DRL policy engine, multi-level stack |
| **Scaffolding Hint** | ✅ Generic template + LLM hint (cached) | Hobby-aware rewrite |
| **24/7 Tutor Chat** | ✅ Basic chat dengan prompt injection guard, handoff ke guru | Voice input, image upload |
| **Cognitive Passport View** | ✅ Read-only P(L) per TP, mastered count | Historical trend chart |
| **Offline Queue** | ✅ Queue jawaban + sync dengan attempt_id idempotency | Conflict resolution UI advanced |
| **Gamification** | ❌ Ditunda | Badge, leaderboard, streak |
| **Personalisasi Hobi** | ❌ Ditunda (fallback ke soal asli) | Hobby-aware content rewrite |

### C. Fitur Parent App (Flutter — Flavor)

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Login & Child List** | ✅ `/parent/children` dengan weekly summary | Multi-child navigation |
| **Weekly Report** | ✅ LLM headline + competency snapshot (no numeric P(L)) | Monthly/semester report |
| **Activity Suggestion** | ✅ Template sederhana (bukan LLM) | LLM hobby-aware activities |
| **Consent Inbox** | ✅ View consent requests + GRANTED/DENIED decision | Bulk consent, consent history export |
| **Push Notification** | ❌ Ditunda (email notif saja) | Push via FCM |

### D. Fitur Teacher Dashboard (React Web)

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Login & Class Select** | ✅ MFA wajib, select kelas dari teaching_assignments | Multi-class view |
| **Differentiation Heatmap** | ✅ 3 kelompok (Fondasi/Reguler/Mahir) P(L) heatmap | Adaptive grouping suggestions |
| **Red Flag List** | ✅ Siswa dengan P(L) < 0.30 + stuck 3+ sesi | ML-powered early warning |
| **Morning Briefing** | ✅ Summary per kelas (fondasi count, red flags, focus TP) | AI-generated lesson plan |
| **Modul Ajar Generator** | ❌ Ditunda (manual upload modul saja) | LLM-generated modul ajar |
| **Student Detail Drill-Down** | ✅ Passport view, quiz log last 5 sessions | Full historical trend |
| **Tutor Handoff Inbox** | ✅ Notifikasi jika tutor flag `TUTOR_HANDOFF_REQUIRED` | In-app chat with student |

### E. Fitur Admin Dashboard (React Web)

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Login & Overview** | ✅ MFA wajib, KPI cards (siswa aktif, avg mastery, red flag rate) | Drill-down per unit |
| **Audit Log Explorer** | ✅ Filter by actor, action, date, risk_level (read-only) | Export CSV, anomaly detection |
| **Ops Health Panel** | ✅ Service status, latency P95, queue depth, GPU util (read-only) | Alerting config UI |
| **System Config** | ✅ View BKT thresholds, LLM flags (read-only) | Edit with reason + approval |
| **User Management** | ✅ List users per tenant (read-only) | CRUD users, role assignment |
| **Transition** | ✅ Single student transition dengan manual approval | Bulk CSV upload |
| **Curriculum Editor** | ❌ Ditunda (seed via migration) | Visual TP/CP/ATP editor |
| **ATP Builder** | ❌ Ditunda (linear sequence hardcoded) | Drag-drop react-flow canvas |

### F. Backend Features

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Auth** | ✅ Keycloak OIDC, JWKS validation, MFA, refresh token rotation | OAuth social login |
| **BKT Engine** | ✅ Core BKT update, default params (0.85/0.20 threshold) | Per-TP calibrated params |
| **Matchmaker State Machine** | ✅ 6 adaptive_status, remediation stack, session persist | DRL policy, multi-objective optimization |
| **Endpoint Coverage** | ✅ `/engine/evaluate`, `/student/*`, `/teacher/*`, `/parent/*`, `/admin/*` (subset) | Full OpenAPI spec (semua endpoint Doc 04) |
| **RLS & Authorization** | ✅ Tenant isolation, ownership check (IDOR prevention) | Fine-grained ABAC |
| **Audit Logging** | ✅ Critical events: login fail, passport access, export, role change | Full event stream |
| **Rate Limiting** | ✅ Redis-based, per-endpoint basic limits | Adaptive rate limit per user tier |

### G. AI & RAG Features

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Ollama LLM** | ✅ llama3:8b-instruct local, prompt injection guard | Mixtral, fine-tuned model |
| **Tutor Chat** | ✅ Basic scaffolding, handoff to teacher | Multi-turn context, voice |
| **Parent Report Headline** | ✅ Template fallback (LLM optional di beta) | Full LLM narrative |
| **Qdrant RAG** | ✅ Embed curriculum + content (nomic-embed-text) | Multi-modal embedding (image/video) |
| **Hobby-Aware Rewrite** | ❌ Ditunda (fallback ke soal asli) | Full rewrite pipeline |
| **Modul Ajar Generator** | ❌ Ditunda | LLM-generated lesson plans |
| **Fallback Mode** | ✅ Template jika Ollama down (§9 Doc 09) | — |
| **Prompt Versioning** | ✅ Log `prompt_version` di setiap call | A/B test prompts |

### H. DevOps & Infrastructure

| Fitur | MVP Scope | Post-MVP |
| :--- | :--- | :--- |
| **Deployment** | ✅ Docker Compose (12 services), single server, nginx multi-subdomain | Kubernetes, multi-node |
| **Database** | ✅ PostgreSQL (aleta_core + unit_smp), Neo4j, Redis, Qdrant | Read replicas, sharding |
| **Backup** | ✅ Daily backup (cron 02:00), 30-day retention, encrypted | Hourly backup, offsite S3 |
| **Monitoring** | ✅ Prometheus + Grafana, basic dashboards (health, latency, GPU) | Full observability stack (Loki, Tempo) |
| **CI/CD** | ✅ Gitea Actions: lint, test, OpenAPI diff gate | Blue-green deployment, canary |
| **GPU** | ✅ Single NVIDIA RTX 3060/4060 Ti (16 GB VRAM) | Multi-GPU, model parallelism |

---

## 3. FITUR YANG DITUNDA (POST-MVP)

Fitur-fitur di bawah **TIDAK** masuk MVP Phase 1. Defer ke Phase 2 setelah pilot sukses (3–6 bulan):

**Kategori Pedagogi**:
* ATP Builder visual (drag-drop graph) — gunakan linear sequence seed.
* DRL policy engine untuk adaptive ATP branching.
* Multi-level remediation stack (MVP: max 1 level prerequisite).
* Hobby-aware content rewrite full pipeline.
* Modul ajar generator LLM.

**Kategori Multi-Tenancy**:
* Multi-unit production (TK/SD/SMP/SMA parallel).
* Bulk transition CSV upload (MVP: manual single transition).
* Cross-jenjang teacher view (MVP: guru hanya lihat unit sendiri).

**Kategori Gamifikasi**:
* Badge, leaderboard, streak tracking.
* Avatar customization, pet companion (Kids mode).
* Mission-based learning paths.

**Kategori Analytics**:
* ML-powered early warning (prediksi dropout risk).
* Recommendation engine untuk aktivitas ekstrakurikuler.
* Full yayasan-wide analytics dashboard.

**Kategori Compliance**:
* Data export PDP workflow dengan approval multi-step.
* Automated data retention purge (MVP: manual script).
* Breach simulation drill.

**Kategori Infra**:
* Kubernetes deployment.
* Multi-region availability.
* Auto-scaling HPA.
* Managed cloud services (RDS, ElastiCache).

---

## 4. SUCCESS METRICS MVP

Setelah 4–8 minggu pilot, ukur:

### A. Engagement Metrics

| Metric | Target MVP | Measurement |
| :--- | :--- | :--- |
| **Daily Active Users (DAU)** | ≥ 60% dari cohort | Login + submit ≥ 1 quiz per hari |
| **Weekly Active Users (WAU)** | ≥ 85% dari cohort | Login + submit ≥ 3 quiz per minggu |
| **Avg Session Duration** | ≥ 15 menit | Median time spent per session |
| **Quiz Completion Rate** | ≥ 70% | (Submitted quizzes / Started quizzes) |

### B. Learning Outcome Metrics

| Metric | Target MVP | Measurement |
| :--- | :--- | :--- |
| **Avg Mastery Velocity** | ≥ 3 TP/minggu | Jumlah TP dengan `is_mastered=true` / minggu per siswa |
| **Remediation Success Rate** | ≥ 60% | (TP mastered after remediation / Total remediation triggered) |
| **Tutor Handoff Rate** | < 10% | (Tutor handoff count / Total quiz sessions) |
| **Misconception Resolution** | ≥ 50% | (Resolved misconceptions / Total detected) dalam 2 minggu |

### C. Teacher Adoption Metrics

| Metric | Target MVP | Measurement |
| :--- | :--- | :--- |
| **Teacher Dashboard Login Rate** | ≥ 3x per minggu | Guru buka dashboard minimal 3 hari per minggu |
| **Red Flag Action Rate** | ≥ 40% | (Red flags with teacher intervention / Total red flags) |
| **Morning Briefing View Rate** | ≥ 70% | Guru buka briefing sebelum kelas (timestamp < 08:00) |

### D. Parent Satisfaction Metrics

| Metric | Target MVP | Measurement |
| :--- | :--- | :--- |
| **Weekly Report Open Rate** | ≥ 60% | Parent buka `/parent/activity-reflection` per minggu |
| **Consent Grant Rate** | ≥ 80% | (Consent GRANTED / Total consent requests) |
| **Parent NPS** | ≥ 40 | Survey setelah 4 minggu pilot |

### E. System Performance Metrics

| Metric | Target MVP | Measurement |
| :--- | :--- | :--- |
| **API P95 Latency** | < 500 ms | `/engine/evaluate` latency |
| **Tutor TTFB** | < 3000 ms | Streaming chat first token |
| **Ollama Queue Depth** | < 5 (P95) | Concurrent LLM requests |
| **Uptime** | ≥ 99% | Exclude planned maintenance |

---

## 5. RELEASE PLAN MVP

### Phase Alpha (Minggu 1–2): 10–20 siswa, 1 guru, 1 kelas

**Goal**: Smoke test end-to-end flow, fix critical bugs, validate core UX.

**Deliverables**:
* [ ] Login berfungsi (Keycloak + JWT).
* [ ] Quiz player render soal + submit jawaban.
* [ ] BKT update berhasil, P(L) disimpan ke passport.
* [ ] Remediation trigger jika P(L) < 0.20.
* [ ] Teacher dashboard show differentiation heatmap.
* [ ] Parent app show weekly summary (template, bukan LLM).
* [ ] Admin dashboard show ops health.

**Exit Criteria**: Zero P0 bugs, ≥ 70% quiz completion rate, teacher satisfied dengan differentiation view.

### Phase Beta (Minggu 3–6): 50–100 siswa, 3 guru, 3 kelas, 3 mata pelajaran

**Goal**: Validate scalability, expand mata pelajaran, refine UX, enable LLM features.

**Deliverables**:
* [ ] Expand ke 3 mata pelajaran (Matematika, IPA, Bahasa Indonesia).
* [ ] Enable tutor chat LLM (with fallback).
* [ ] Enable parent report LLM headline (with fallback template).
* [ ] Refine red flag algorithm based on teacher feedback.
* [ ] Optimize Ollama latency (target P95 < 2.5s).

**Exit Criteria**: ≥ 60% DAU, ≥ 3 TP/minggu mastery velocity, teacher NPS ≥ 50, parent NPS ≥ 40.

### Phase Production Pilot (Minggu 7–16): 200 siswa, 10 guru, 10 kelas

**Goal**: Production-ready untuk cohort besar, measure long-term retention, prepare for multi-unit expansion.

**Deliverables**:
* [ ] 200 siswa aktif dengan ≥ 85% WAU.
* [ ] Teacher training selesai (onboarding + best practice).
* [ ] Parent satisfaction survey (target NPS ≥ 40).
* [ ] Backup & restore test passed.
* [ ] Security audit (IDOR, prompt injection, tenant leak) passed.
* [ ] Performance benchmark: 50 RPS sustained, P95 < 500ms.

**Exit Criteria**: ≥ 85% WAU, ≥ 3 TP/minggu, tutor handoff < 10%, uptime ≥ 99%, ready for multi-unit expansion.

---

## 6. MVP DO NOT DO LIST (Anti-Scope Creep)

❌ **Jangan implement fitur ini di MVP**:

* Jangan buat UI mode Kids/Junior (hanya Pro Dashboard untuk SMP).
* Jangan buat ATP builder visual (linear sequence cukup).
* Jangan buat curriculum editor web (seed via migration).
* Jangan buat multi-unit parallel (fokus 1 SMP dulu).
* Jangan buat modul ajar generator full (template manual cukup).
* Jangan buat gamification (badge/leaderboard) — fokus learning dulu.
* Jangan buat export PDP workflow kompleks (manual approval cukup).
* Jangan deploy ke Kubernetes (Docker Compose cukup).
* Jangan optimize untuk 1000+ siswa (fokus 200 siswa dulu).
* Jangan buat multi-language (Bahasa Indonesia only).

---

## 7. CHECKLIST SEBELUM DECLARE MVP DONE

* [ ] Semua acceptance criteria Phase Production Pilot terpenuhi.
* [ ] Success metrics (§4) minimal 80% tercapai.
* [ ] Security audit (§5a Doc 07) passed: IDOR, tenant leak, JWT forgery, prompt injection.
* [ ] Backup restore test passed (RTO ≤ 2 jam).
* [ ] Load test: 50 RPS sustained selama 1 jam, P95 < 500ms, no crash.
* [ ] Teacher training selesai + feedback incorporated.
* [ ] Parent onboarding selesai + consent >80% granted.
* [ ] Documentation lengkap: README, user guide, troubleshooting.
* [ ] Monitoring dashboard production-ready (Grafana).
* [ ] Incident response playbook siap (Doc 07 §E breach playbook).

---

**END OF MVP_SCOPE.md**

> 🎯 **Remember**: MVP sukses bukan berarti semua fitur jalan, tapi berarti **value proposition terbukti** dengan data real dari cohort real dalam production environment real.
