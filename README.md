# FILE: README.md
# PROJECT ALETA: COMPREHENSIVE BLUEPRINTS INDEX & REPO NAVIGATOR

## 1. PENDAHULUAN
Selamat datang di repositori arsitektur **Project ALETA (AI-powered Learning Ecosystem for Tailored Achievement)**. Ekosistem ini dirancang khusus untuk skala organisasi/Yayasan yang menaungi jenjang pendidikan terpadu mulai dari TK (Fase Fondasi), SD (Fase A-C), SMP (Fase D), hingga SMA/SMK (Fase E-F).

Seluruh dokumen di dalam repositori ini ditulis dengan spesifikasi teknis tinggi, berorientasi pada data, dan menggunakan format yang siap dikonsumsi langsung oleh mesin (*Vibe Coding Ready*) seperti LLM (Claude/GPT) atau AI-powered IDE (Cursor/Windsurf).

## 1.1 ALETA SEBAGAI AI-POWERED ADAPTIVE LMS

ALETA tidak menggunakan LMS eksternal seperti Moodle atau Google Classroom sebagai fondasi utama. Seluruh fungsi LMS seperti manajemen konten, kelas, siswa, aktivitas belajar, kuis, progress, dashboard guru, autentikasi, dan deployment merupakan bagian native dari arsitektur ALETA.

Perbedaannya dari LMS konvensional adalah setiap materi, kuis, rekomendasi, dan tampilan belajar tidak disajikan secara statis, melainkan dipilih secara adaptif berdasarkan **Cognitive Passport**, graph prasyarat CP/TP/ATP, dan **Bayesian Knowledge Tracing (BKT)**. Dengan demikian, Project ALETA harus dipahami sebagai **AI-Powered Adaptive LMS native** untuk Yayasan pendidikan multi-jenjang, bukan sebagai AI engine yang ditempelkan ke LMS lain.

---

## 2. PETA NAVIGASI DOKUMEN (BLUEPRINT INDEX)

Silakan gunakan daftar di bawah ini sebagai urutan referensi saat memberikan konteks kepada AI di lingkungan pengembangan Anda:

### 🧠 KELOMPOK 1: FONDASI & LOGIKA KURIKULUM (THE "BRAIN" CONFIG)
*   **[01_CURRICULUM_ONTOLOGY_GRAPH.md](./01_CURRICULUM_ONTOLOGY_GRAPH.md)**
    *   *Fokus:* Desain skema Graph Database (Neo4j) untuk memetakan dokumen Capaian Pembelajaran (CP), Tujuan Pembelajaran (TP), dan Alur Tujuan Pembelajaran (ATP) Kurikulum Merdeka.
    *   *Aset Kode:* Skema visual ASCII, batasan data (*constraints*), dan contoh query Cypher siap pakai.
*   **[02_ADAPTIVE_ENGINE_SPEC.md](./02_ADAPTIVE_ENGINE_SPEC.md)**
    *   *Fokus:* Spesifikasi matematika untuk mesin adaptif menggunakan *Bayesian Knowledge Tracing* (BKT) dan logika pengalihan rute remedial otomatis (*remedial rerouting*).
    *   *Aset Kode:* Kode Python mandiri `adaptive_engine.py` untuk kalkulasi probabilitas penguasaan materi ($P(L)$) siswa.

### 💻 KELOMPOK 2: ARSITEKTUR SISTEM & DATA (THE "SPINE" TECH)
*   **[03_DATABASE_SCHEMA_MULTI_TENANTS.md](./03_DATABASE_SCHEMA_MULTI_TENANTS.md)**
    *   *Fokus:* Desain database relasional terpusat menggunakan PostgreSQL dengan pendekatan *Shared Database, Separate Schema* untuk memisahkan data tiap unit sekolah.
    *   *Aset Kode:* Skema SQL DDL lengkap dengan *database trigger* otomatisasi kelulusan kompetensi.
*   **[04_BACKEND_API_CONTRACTS.md](./04_BACKEND_API_CONTRACTS.md)**
    *   *Fokus:* Spesifikasi kontrak komunikasi data RESTful API berbasis JSON antara aplikasi pengguna dengan layanan inti backend.
    *   *Aset Kode:* Payload JSON untuk otorisasi, paspor kognitif, evaluasi mesin, dan struktur kode *controller* FastAPI (Python).

### 📱 KELOMPOK 3: ANTARMUKA & INTERACTION (THE "FACE" UI/UX)
*   **[05_FRONTEND_DYNAMIC_UI_FLUTTER.md](./05_FRONTEND_DYNAMIC_UI_FLUTTER.md)**
    *   *Fokus:* Arsitektur aplikasi mobile multi-platform Flutter yang merender tema dan komponen visual secara dinamis dikendalikan oleh data Fase login siswa.
    *   *Aset Kode:* Komponen Factory Dart, konfigurasi tema, dan kontrak state BLoC.
*   **[06_TEACHER_DASHBOARD_ANALYTICS.md](./06_TEACHER_DASHBOARD_ANALYTICS.md)**
    *   *Fokus:* Logika pengolah data analitik dasbor web berbasis React.js untuk membantu guru mengambil tindakan instan di kelas.
    *   *Aset Kode:* Fungsi pemroses data dalam TypeScript dan komponen antarmuka React (TSX) untuk memetakan kelompok diferensiasi kelas dan peringatan dini (*Red Flag*).

### 🛡️ KELOMPOK 4: OPERASIONAL & KEDAULATAN DATA (THE "SHIELD" OPS)
*   **[07_SECURITY_PRIVACY_PASSPORT.md](./07_SECURITY_PRIVACY_PASSPORT.md)**
    *   *Fokus:* Protokol perlindungan privasi anak dan jaminan keamanan rekam jejak kognitif 12 tahun sesuai dengan regulasi UU PDP Indonesia No. 27 Tahun 2022.
    *   *Aset Kode:* Skema klaim token JWT, middleware filter keamanan Python, tabel retensi konkret, playbook breach notification, perintah *Row-Level Security* (RLS) PostgreSQL.
*   **[08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md](./08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md)**
    *   *Fokus:* Spesifikasi infrastruktur operasional dengan 12 service (Postgres, Neo4j, Redis, Ollama, Qdrant, Keycloak, Core API, AI Engine, Teacher Dashboard, Admin Dashboard, Nginx, Backup).
    *   *Aset Kode:* `docker-compose.yml` lengkap, `nginx.conf` multi-subdomain, dan panduan model download.

### 🧩 KELOMPOK 5: EKSTENSI ADAPTIF & STAKEHOLDER LAINNYA
*   **[09_RAG_AND_TUTOR_SPEC.md](./09_RAG_AND_TUTOR_SPEC.md)**
    *   *Fokus:* Arsitektur RAG (Qdrant + Ollama nomic-embed-text), pipeline personalisasi soal berbasis hobi siswa, dan chatbot tutor 24/7 dengan prompt-injection guard berlapis.
*   **[10_PARENT_APP_SPEC.md](./10_PARENT_APP_SPEC.md)**
    *   *Fokus:* Aplikasi orang tua sebagai Flutter build flavor terpisah; laporan tanpa nilai numerik, saran aktivitas rumah, consent inbox.
*   **[11_ADMIN_YAYASAN_DASHBOARD.md](./11_ADMIN_YAYASAN_DASHBOARD.md)**
    *   *Fokus:* Dashboard React admin yayasan; ATP Builder, sistem config kalibrasi tanpa redeploy, audit log explorer.
*   **[12_CROSS_JENJANG_TRANSITION.md](./12_CROSS_JENJANG_TRANSITION.md)**
    *   *Fokus:* Orchestrator transisi siswa TK→SD→SMP→SMA (state machine, idempotent, reversible 7 hari, bulk transition).
*   **[13_MIGRATIONS_AND_CICD.md](./13_MIGRATIONS_AND_CICD.md)**
    *   *Fokus:* Alembic migrations, OpenAPI export gate, Gitea Actions CI, Keycloak realm export, backup off-site, Loki+Grafana.
*   **[14_UI_UX_DESIGN_SYSTEM.md](./14_UI_UX_DESIGN_SYSTEM.md)**
    *   *Fokus:* Design tokens (JSON canonical), tipografi per-fase, komponen + state matrix, user flows per persona (Mermaid), microcopy & voice guidelines, gesture map kid-safe, WCAG 2.2 AA checklist, motion & illustration budget, brand identity, Figma file index.
*   **[15_PROJECT_STRUCTURE.md](./15_PROJECT_STRUCTURE.md)**
    *   *Fokus:* Pohon folder monorepo lengkap (5 service + packages + infrastructure + docs + scripts), naming conventions per bahasa, module boundaries, ownership map (folder ↔ blueprint), tabel resolusi inkonsistensi path, .gitignore policy, Makefile top-level. **Single source of truth** struktur file project.
*   **[16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md](./16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md)**
    *   *Fokus:* Playbook eksekusi multi-agent (Claude & lainnya). 5 aturan anti-drift, dependency graph implementasi, 8 phase milestone (Day 0–56), multi-agent topology + role definitions, model selection (Opus/Sonnet/Haiku), 60+ task card format YAML, sample prompts per role, anti-drift checklist per commit/PR/merge/sync, handoff contracts, failure modes & recovery, release gates. **Wajib dibaca sebelum mulai coding.**
*   **[17_MASTER_PROMPT_AND_STATE.md](./17_MASTER_PROMPT_AND_STATE.md)**
    *   *Fokus:* Spesifikasi master prompt multi-agent ALETA-OPS v1.0 + arsitektur `STATE.yaml`. 10 teknik canggih (Triple-Reference Discipline, Phase Lock, JIT section anchors, Self-Quote Before Claim, Sentinel Honor, Adversarial Inner Skeptic, Atomic State Patches, Compressed Shorthand, Budget-Aware Forced Compaction, Output Minimization). Output schema YAML mandatory, halt protocol, role overlays, contoh siklus hidup end-to-end.

### 🚀 ARTEFAK OPERASIONAL (di root repo, bukan blueprint)
*   **[MASTER_PROMPT.md](./MASTER_PROMPT.md)** — prompt copy-paste-ready untuk sesi Claude/agent.
*   **[STATE.yaml](./STATE.yaml)** — file state kanonik berisi 89 task ledger + sentinels + file ledger. Di-update oleh agent via `state_patches` atomic.

---

## 3. LANGKAH AWAL MEMULAI PEMROGRAMAN (VIBE CODING PROMPT)
Saat Anda pertama kali membuka proyek ini bersama asisten AI (misalnya Cursor IDE), salin teks perintah (*prompt*) di bawah ini ke dalam chat panel untuk memberikan konteks awal yang sempurna:

```ini
Halo AI! Kita akan membangun Project ALETA, sebuah ekosistem aplikasi e-learning adaptif berbasis Kurikulum Merdeka skala Yayasan (TK-SMA). 
Saya sudah menyiapkan 8 dokumen cetak biru (blueprint) teknis lengkap di repositori ini yang mendefinisikan grafik kurikulum, mesin BKT, skema database multi-tenant, kontrak API, frontend Flutter dynamic UI, analitik dasbor React, protokol UU PDP, hingga Docker Compose.

Langkah pertama, tolong baca dan pahami file '01_CURRICULUM_ONTOLOGY_GRAPH.md' dan '03_DATABASE_SCHEMA_MULTI_TENANTS.md'. Setelah kamu memahaminya, beritahu saya struktur folder backend pertama yang harus kita buat untuk mengimplementasikan database ini.

```

---

## 4. TATA TERTIB PENGEMBANGAN TIM IT YAYASAN

1. **Gunakan Akun Tunggal (SSO):** Dilarang keras membuat tabel akun pengguna lokal baru di skema penyewa (*tenant schemas*). Semua identitas wajib merujuk ke tabel `aleta_core.users`.
2. **Pertahankan Hubungan Prasyarat:** Setiap kali ada penambahan materi atau Tujuan Pembelajaran (TP) baru oleh tim kurikulum Yayasan, pastikan relasi `HAS_PREREQUISITE` pada Neo4j diverifikasi agar jalur belajar adaptif siswa tidak rusak.
3. **Kedaulatan Data Lokal:** Seluruh pemrosesan kecerdasan buatan wajib dialirkan melalui kontainer `aleta_ollama` lokal. Dilarang melakukan *hardcoding* pengiriman data identitas siswa ke API AI eksternal komersial demi mematuhi hukum privasi data anak.

```

---
