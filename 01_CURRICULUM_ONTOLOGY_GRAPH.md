---
doc: "01"
title: "Curriculum Ontology Graph"
scope: "Neo4j schema: Institution→Unit→Fase→CP→TP nodes, HAS_PREREQUISITE + MAY_TRIGGER edges, Cypher seed stubs"
key_entities: [Institution, Unit, Fase, Subject, CP, TP, ContentItem, HAS_PREREQUISITE, MAY_TRIGGER]
depends_on: ["00"]
loaded_by_tasks: [T-103, T-203]
---

# FILE: 01_CURRICULUM_ONTOLOGY_GRAPH.md
# PROJECT ALETA: CURRICULUM ONTOLOGY GRAPH SPECIFICATION

## 1. PENDAHULUAN & FILOSOFI DESAIN
Dokumen ini mendefinisikan skema Knowledge Graph (Ontologi) untuk memetakan dokumen Kurikulum Merdeka (Fase Fondasi hingga Fase F) ke dalam Neo4j Graph Database. 

Penggunaan Graph Database sangat krusial dalam ALETA karena Kurikulum Merdeka mengandalkan konsep kompetensi berkelanjutan. Dibandingkan dengan database relasional (SQL) yang membutuhkan join tabel yang lambat, Graph Database memungkinkan ALETA melakukan pencarian jalur prasyarat materi (*prerequisite routing*) lintas jenjang secara instan (<10ms).

---

## 2. MODEL ENTITAS (NODE LABELS)
Berikut adalah daftar Node beserta properti kunci yang harus dideklarasikan dalam sistem database ALETA:

### A. Node: `Institution`
Mewakili entitas pusat (Yayasan) yang menaungi seluruh unit sekolah.
*   **Properties:**
    *   `id`: UUID (Primary Key)
    *   `name`: String (e.g., "Yayasan Pendidikan Merdeka")

### B. Node: `Unit`
Mewakili jenjang sekolah di bawah yayasan.
*   **Properties:**
    *   `id`: UUID
    *   `type`: String ENUM (`TK`, `SD`, `SMP`, `SMA`, `SMK`)
    *   `name`: String (e.g., "SD Merdeka Inti")

### C. Node: `Fase`
Mewakili pembagian fase perkembangan dalam Kurikulum Merdeka.
*   **Properties:**
    *   `id`: String (e.g., "FASE_A", "FASE_D", "FASE_F")
    *   `name`: String (e.g., "Fase D")
    *   `target_kelas`: String Array (e.g., `["7", "8", "9"]`)

### D. Node: `Subject`
Mewakili mata pelajaran.
*   **Properties:**
    *   `id`: String (e.g., "MATEMATIKA", "BAHASA_INDONESIA")
    *   `name`: String (e.g., "Matematika")

### E. Node: `Elemen`
Mewakili rumpun kompetensi di dalam satu mata pelajaran.
*   **Properties:**
    *   `id`: String (e.g., "MAT_ALJABAR", "MAT_GEOMETRI")
    *   `name`: String (e.g., "Aljabar")

### F. Node: `CP` (Capaian Pembelajaran)
Teks target kompetensi resmi dari pemerintah.
*   **Properties:**
    *   `id`: UUID
    *   `description`: String (Teks narasi CP asli)
    *   `source_law`: String (e.g., "BSKAP No. 032/H/2024")

### G. Node: `TP` (Tujuan Pembelajaran)
Pecahan kompetensi spesifik yang diturunkan oleh guru/yayasan dari CP.
*   **Properties:**
    *   `id`: String (e.g., "TP_MAT_7_1")
    *   `competency`: String (Kata kerja operasional, e.g., "Memahami")
    *   `content`: String (Materi, e.g., "Bentuk Aljabar Satu Variabel")
    *   `bloom_level`: Integer (Level Taksonomi Bloom, 1-6)

### H. Node: `ContentItem`
Aset digital pembelajaran (video, kuis, artikel) yang terikat pada suatu TP.
*   **Properties:**
    *   `id`: UUID
    *   `title`: String
    *   `type`: String ENUM (`VIDEO`, `QUIZ`, `ARTICLE`, `GAME`)
    *   `url_path`: String
    *   `difficulty_rating`: Float (Skala 0.0 - 1.0, disesuaikan dinamis oleh AI; lihat algoritma di `02_ADAPTIVE_ENGINE_SPEC.md` §6)
    *   `tags`: String Array (e.g., `["video", "scaffolding", "low-text"]`)

### I. Node: `Misconception` *(Peta Miskonsepsi)*
Mewakili pola kesalahan berpikir khas yang teridentifikasi dari log jawaban kuis siswa. Node ini adalah benang merah "peta miskonsepsi 12 tahun" yang dijanjikan pada `00_EXECUTIVE_SUMMARY.md` §3.
*   **Properties:**
    *   `id`: String (e.g., "MIS_MAT_FRAC_INVERT", "MIS_BIN_PLACEHOLDER")
    *   `name`: String (e.g., "Membalik pembilang/penyebut saat mengurangi pecahan")
    *   `description`: String
    *   `detection_signature`: String (kueri/regex/aturan deteksi pada log jawaban)
    *   `severity`: Integer (1-5)

### J. Node: `ATPSequence` *(Alur Tujuan Pembelajaran resmi per Unit)*
ATP berbeda dari `HAS_PREREQUISITE`: ATP adalah **urutan kanonik** yang ditetapkan unit sekolah, sedangkan `HAS_PREREQUISITE` adalah graf prasyarat lintas-fase. Satu TP bisa muncul di banyak ATP berbeda.
*   **Properties:**
    *   `id`: UUID
    *   `name`: String (e.g., "ATP Matematika Kelas 7 Semester 1 - SMP Bina Cerdas")
    *   `tenant_id`: String (mengikat ATP ke satu Unit sekolah)
    *   `academic_year`: String (e.g., "2025/2026")
    *   `position_map`: JSON String (`{"TP_MAT_7_ALJABAR": 1, "TP_MAT_7_PLSV": 2, ...}`)

---

## 3. MODEL HUBUNGAN (RELATIONSHIP TYPES)
Hubungan antar-node yang mendikte aliran logika navigasi sistem ALETA:

| Source Node | Relationship | Target Node | Deskripsi/Aturan Bisnis |
| :--- | :--- | :--- | :--- |
| `Unit` | `BELONGS_TO` | `Institution` | Tata kelola kepemilikan unit sekolah di bawah yayasan. |
| `Unit` | `MANAGES_FASE` | `Fase` | Memetakan fase apa saja yang dikelola oleh unit tertentu. |
| `Elemen` | `PART_OF` | `Subject` | Menandakan elemen tersebut milik suatu mata pelajaran. |
| `CP` | `BOUNDS_TO` | `Fase` | CP mengikat secara kaku pada satu Fase tertentu. |
| `CP` | `CATEGORIZED_BY`| `Elemen` | CP dikelompokkan berdasarkan rumpun elemennya. |
| `TP` | `DERIVED_FROM` | `CP` | Guru memecah kalimat CP menjadi beberapa item TP. |
| `TP` | `HAS_PREREQUISITE`| `TP` | **(Kunci Adaptivitas)** Murid tidak bisa membuka target TP sebelum menguasai TP Prasyarat (bisa lintas fase). |
| `ContentItem`| `TEACHES` | `TP` | Aset digital ini berfungsi sebagai bahan ajar untuk TP terkait. |
| `TP` | `MAY_TRIGGER` | `Misconception` | Jawaban salah pada TP ini sering kali memicu pola miskonsepsi terkait. |
| `Misconception` | `BLOCKS` | `TP` | Selama miskonsepsi belum diatasi, TP target sulit dikuasai meskipun prasyarat tampak terpenuhi. |
| `ATPSequence` | `CONTAINS` | `TP` | TP yang menjadi anggota urutan ATP resmi unit (dengan order index pada properti relasi `position`). |
| `ATPSequence` | `MANAGED_BY` | `Unit` | ATP dimiliki dan dikurasi oleh satu Unit. |

---

## 4. SKEMA GRAFIK VISUAL (ASCII ART)
Untuk mempermudah pemahaman LLM saat *Vibe Coding*, berikut adalah peta konektivitas jaringannya:


```

(Institution)
▲
│ [BELONGS_TO]
(Unit) ────[MANAGES_FASE]────► (Fase)
▲
│ [BOUNDS_TO]
(Subject)                          │
▲                               │
│ [PART_OF]                     │
(Elemen) ◄─────[CATEGORIZED_BY]── (CP)
▲
│ [DERIVED_FROM]
(ContentItem) ───[TEACHES]─────────► (TP) ───[HAS_PREREQUISITE]──► (TP prasyarat)

```

---

## 5. QUERY IMPLEMENTASI CYPHER (SIAP PAKAI DI NEO4J)

### A. Membuat Constraints (Validasi Data Integrity)
Jalankan query ini saat inisialisasi database untuk memastikan tidak ada duplikasi ID:
```cypher
CREATE CONSTRAINT unique_institution_id IF NOT EXISTS FOR (i:Institution) REQUIRE i.id IS UNIQUE;
CREATE CONSTRAINT unique_unit_id IF NOT EXISTS FOR (u:Unit) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT unique_fase_id IF NOT EXISTS FOR (f:Fase) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT unique_subject_id IF NOT EXISTS FOR (s:Subject) REQUIRE s.id IS UNIQUE;
CREATE CONSTRAINT unique_tp_id IF NOT EXISTS FOR (t:TP) REQUIRE t.id IS UNIQUE;

```

### B. Contoh Kasus: Memasukkan Data Fondasi (TK) hingga Aljabar SMP (Fase D)

Contoh pengisian data untuk mendemonstrasikan jembatan prasyarat materi dari Fase Fondasi (TK) ke Fase D (SMP):

```cypher
// 1. Create Core Structures
MERGE (inst:Institution {id: "YAYASAN_XYZ", name: "Yayasan Bina Cerdas"})
MERGE (tk:Unit {id: "TK_XYZ", name: "TK Bina Cerdas", type: "TK"})-[:BELONGS_TO]->(inst)
MERGE (smp:Unit {id: "SMP_XYZ", name: "SMP Bina Cerdas", type: "SMP"})-[:BELONGS_TO]->(inst)

MERGE (fFondasi:Fase {id: "FASE_FONDASI", name: "Fase Fondasi", target_kelas: ["TK_A", "TK_B"]})
MERGE (fD:Fase {id: "FASE_D", name: "Fase D", target_kelas: ["7", "8", "9"]})

MERGE (tk)-[:MANAGES_FASE]->(fFondasi)
MERGE (smp)-[:MANAGES_FASE]->(fD)

MERGE (mat:Subject {id: "MATEMATIKA", name: "Matematika"})
MERGE (elBil:Elemen {id: "MAT_BILANGAN", name: "Bilangan"})-[:PART_OF]->(mat)
MERGE (elAlj:Elemen {id: "MAT_ALJABAR", name: "Aljabar"})-[:PART_OF]->(mat)

// 2. Create CP
MERGE (cpTK:CP {id: "CP_MAT_TK", description: "Anak mengenali pola, bentuk, dan dasar membilang", source_law: "2024"})
MERGE (cpTK)-[:BOUNDS_TO]->(fFondasi)
MERGE (cpD:CP {id: "CP_MAT_SMP_ALJ", description: "Peserta didik dapat menyatakan situasi ke dalam bentuk aljabar", source_law: "BSKAP 032/2024"})
MERGE (cpD)-[:BOUNDS_TO]->(fD)
MERGE (cpD)-[:CATEGORIZED_BY]->(elAlj)

// 3. Create TP & Prerequisite Link (The Core Adaptive Logic)
MERGE (tpTK:TP {id: "TP_MAT_TK_COUNT", competency: "Membilang", content: "Objek konkret hingga 10", bloom_level: 1})-[:DERIVED_FROM]->(cpTK)
MERGE (tpSMP:TP {id: "TP_MAT_7_ALJABAR", competency: "Menyederhanakan", content: "Bentuk Aljabar Linear", bloom_level: 3})-[:DERIVED_FROM]->(cpD)

// AI Core rule: Siswa tidak bisa paham Aljabar SMP jika saat TK belum bisa konsep membilang dasar
MERGE (tpSMP)-[:HAS_PREREQUISITE]->(tpTK)

```

---

## 6. LOGIKA QUERY UNTUK VIBE CODING (BACKEND API INTEGRATION)

### API Kasus 1: Mengambil Rute Belajar Siswa (ATP) Berdasarkan Kondisi Prasyarat

Ketika aplikasi siswa meminta daftar materi hari ini, backend akan mengeksekusi query berikut untuk mencari TP mana yang *lock* (kunci) karena prasyarat belum terpenuhi oleh siswa tersebut:

```cypher
MATCH (target_tp:TP {id: $current_target_tp})
MATCH (target_tp)-[:HAS_PREREQUISITE]->(prereq:TP)
// Sistem akan mencocokkan apakah ID prereq ini sudah ada di daftar 'mastered_tps' pada profil SQL siswa
RETURN prereq.id AS required_tp_id, prereq.content AS material_name

```

### API Kasus 2: Micro-Remediation Rerouting (Pelacakan Akar Miskonsepsi)

Jika siswa SMA/SMP gagal berkali-kali di satu TP, mesin AI akan memanggil query ini untuk menarik garis mundur (mundur ke belakang) guna menemukan kompetensi dasar paling awal yang belum dikuasai (bisa mendeteksi hingga pelajaran tingkat SD):

```cypher
MATCH path = (start:TP {id: $failed_tp_id})-[:HAS_PREREQUISITE*1..5]->(ancestor:TP)
RETURN [n in nodes(path) | {id: n.id, content: n.content, level: n.bloom_level}] AS remedial_track
LIMIT 1

```

### API Kasus 3: Deteksi Miskonsepsi Aktif dari Pola Jawaban

Saat `MatchmakerEngine` menemukan jawaban salah pada TP, query ini memetakan miskonsepsi yang paling mungkin sedang aktif (untuk diteruskan ke prompt RAG di `09_RAG_AND_TUTOR_SPEC.md`):

```cypher
MATCH (t:TP {id: $current_tp_id})-[:MAY_TRIGGER]->(m:Misconception)
OPTIONAL MATCH (m)-[:BLOCKS]->(blocked:TP)
RETURN m.id AS misconception_id, m.name AS name, m.severity AS severity,
       collect(blocked.id) AS blocked_tp_ids
ORDER BY m.severity DESC
LIMIT 3

```

### API Kasus 4: Mengambil ATP Resmi Unit untuk Kelas Tertentu

Query ini dipanggil oleh dashboard guru (`06_TEACHER_DASHBOARD_ANALYTICS.md`) atau aplikasi siswa (`05_FRONTEND_DYNAMIC_UI_FLUTTER.md`) saat ingin merender peta misi harian:

```cypher
MATCH (atp:ATPSequence {tenant_id: $tenant_id, academic_year: $year})
MATCH (atp)-[r:CONTAINS]->(tp:TP)
RETURN tp.id AS tp_id, tp.content AS content, r.position AS position
ORDER BY r.position ASC

```