---
doc: "09"
title: "RAG and Tutor Spec"
scope: "Qdrant+Ollama RAG pipeline, hobby-aware content rewrite, 24/7 tutor chat dengan 3-layer prompt safety"
key_entities: [Chunker, Embedder, Retriever, Rewriter, TutorSystem, Qdrant, aleta_ollama, prompt_safety]
depends_on: ["03", "04", "08"]
loaded_by_tasks: [T-501, T-503, T-504, T-505, T-506, T-507, T-508]
---

# FILE: 09_RAG_AND_TUTOR_SPEC.md
# PROJECT ALETA: RAG ARCHITECTURE & 24/7 TUTOR SPECIFICATION

## 1. PENDAHULUAN

Dokumen ini menutup gap "Contextual RAG Ingestion" dan "Chatbot Tutor 24/7" yang dijanjikan oleh `00_EXECUTIVE_SUMMARY.md`. Dua fitur ini berbagi infrastruktur LLM yang sama (Ollama lokal + Qdrant vector DB), karena itu disatukan dalam satu blueprint.

Tujuan:
1. Menyajikan personalisasi konten soal berbasis hobi/minat siswa tanpa mengubah esensi Tujuan Pembelajaran (TP).
2. Menyediakan tutor percakapan yang aman bagi anak, dengan retrieval dari curriculum corpus dan log belajar siswa terbaru.
3. Mempertahankan kedaulatan data — **0 panggilan ke API eksternal**.

---

## 2. KOMPONEN INFRASTRUKTUR

| Komponen | Pilihan Default | Alasan |
| :--- | :--- | :--- |
| LLM inference | **Ollama** dengan `llama3:8b-instruct` (CPU/GPU), fallback `phi3:mini` untuk node low-spec | Self-hosted, latensi p95 < 3 detik pada GPU mid-range |
| Embedding model | `nomic-embed-text` via Ollama (dimensi 768) | Multilingual baik untuk bahasa Indonesia |
| Vector DB | **Qdrant** (`aleta_vector_db` di Doc 08) | API HTTP sederhana, mendukung payload filter, on-disk + RAM hybrid |
| Document store mentah | PostgreSQL `aleta_core.rag_documents` | Source of truth + audit |
| Cache prompt/output | Redis DB 1 (`aleta_redis`) | Memangkas latency saat siswa minta ulang scaffold serupa |

---

## 3. CORPUS & INGESTION

### A. Sumber Corpus
1. **Dokumen kurikulum resmi** (CP/TP/ATP dari BSKAP, PDF Modul Ajar Yayasan). Diingest oleh admin yayasan via `POST /api/v1/admin/rag/ingest`.
2. **Cuplikan ContentItem** yang ter-publish (judul + transcript video + caption).
3. **Catatan miskonsepsi historis** (Doc 03 §3.E) — *informational only*, tidak dipakai untuk membentuk jawaban langsung.

### B. Tabel `rag_documents`

```sql
CREATE TABLE aleta_core.rag_documents (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_type VARCHAR(40) NOT NULL CHECK (source_type IN ('CURRICULUM_OFFICIAL','MODUL_AJAR','CONTENT_ITEM','MISCONCEPTION_NOTE')),
    title VARCHAR(200) NOT NULL,
    subject_id VARCHAR(50),
    fase VARCHAR(20),
    tp_ids VARCHAR(50)[],
    raw_text TEXT NOT NULL,
    sha256 CHAR(64) NOT NULL UNIQUE,
    ingested_by UUID REFERENCES aleta_core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### C. Chunking
* Strategi: **paragraph-aware sliding window** 512 token, overlap 64 token.
* Bahasa Indonesia: tokenizer `nomic-embed-text` bawaan.
* Setiap chunk diberi metadata: `document_id`, `chunk_index`, `subject_id`, `fase`, `tp_ids`.

### D. Embedding & Upsert ke Qdrant

```python
# ai_engine/ai_engine/rag/ingest.py (ringkasan)
def ingest_document(doc: RagDocument):
    chunks = chunk_paragraph_aware(doc.raw_text, max_tokens=512, overlap=64)
    vectors = ollama_embed(model="nomic-embed-text", texts=[c.text for c in chunks])
    points = [
        {
            "id": str(uuid.uuid4()),
            "vector": v,
            "payload": {
                "document_id": str(doc.document_id),
                "chunk_index": i,
                "subject_id": doc.subject_id,
                "fase": doc.fase,
                "tp_ids": doc.tp_ids,
                "text": c.text,
            },
        }
        for i, (c, v) in enumerate(zip(chunks, vectors))
    ]
    qdrant.upsert(collection_name="aleta_curriculum", points=points)
```

### E. Re-ingestion Trigger
* Manual via endpoint admin.
* Otomatis ketika `aleta_core.rag_documents.sha256` berubah (jobs nightly).

---

## 4. CHATBOT TUTOR 24/7

### A. Endpoint & Tabel
Lihat `04_BACKEND_API_CONTRACTS.md` §3.F (`POST /api/v1/tutor/chat`) dan `03_…` §3.K (`tutor_conversations`, `tutor_messages`).

### B. Alur Permintaan

```
Siswa kirim message
  → Server buat/ambil conversation
  → Build context:
      - System prompt (fixed; tidak boleh diganti user)
      - Profil afektif siswa (interest_vector, learning_style) — TANPA PII
      - Snapshot 5 baris terakhir tutor_messages dari conversation
      - Retrieval Qdrant: top-k=5 dengan filter payload tp_ids ∋ context_tp_id
  → Sanitasi input user (prompt-injection guard)
  → Ollama streaming /api/chat
  → Stream SSE ke client
  → Setelah selesai: simpan ASSISTANT message + safety_flags
```

### C. System Prompt Tetap (Fixed, Server-Side)

```
Kamu adalah Tutor ALETA untuk siswa Kurikulum Merdeka jenjang {fase_aktif}.
Aturan absolut:
- Jangan beri jawaban akhir untuk soal aktif; bimbing langkah demi langkah.
- Bahasa Indonesia santun, kalimat pendek, sesuai usia siswa.
- Jangan kumpulkan/menanyakan informasi pribadi (nama lengkap orang tua, alamat, sekolah, dll).
- Jika siswa menanyakan topik di luar mata pelajaran, ajak kembali ke materi belajar.
- Jika siswa menunjukkan tanda distress (kesedihan, ancaman bahaya diri), berhenti tutor mode dan tampilkan pesan "TUTOR_HANDOFF_REQUIRED" tanpa konten lain.
Konteks retrieved:
{retrieved_chunks}
Profil siswa (anonim):
{anonymized_profile}
```

### D. Prompt Injection Guard

Lapis 1 — **input sanitizer**: regex menolak token `<|im_start|>`, `### Instruksi`, "ignore previous", dan menormalkan whitespace.

Lapis 2 — **role enforcement**: server selalu kirim `system` lalu `user`. Tidak menerima `system` dari client.

Lapis 3 — **output filter**: post-process untuk mendeteksi keyword forbidden (PII leakage, jawaban akhir saat mode scaffolding aktif). Jika terdeteksi, tag `safety_flags.flagged=true` dan render placeholder.

### E. Safety Handoff

Jika output mengandung `TUTOR_HANDOFF_REQUIRED`:
1. Tulis `audit_events` `action='TUTOR_HANDOFF'` `risk_level='HIGH'`.
2. Kirim notifikasi ke `homeroom_teacher_id` kelas siswa via `aleta_core.notifications`.
3. UI siswa menampilkan kartu "Yuk, hubungi Bu/Pak guru BK kamu" — tidak melanjutkan chat.

### F. Latency & Caching
* Cache respon scaffolding hint (status `CONTINUE_PRACTICE` di Doc 02) di Redis dengan key `scaffold:{tp_id}:{misconception_id}:{interest_hash}` TTL 1 jam.
* Streaming wajib mulai dalam 800 ms; jika model belum siap, fallback ke pesan template (lihat §4.G).

### G. Fallback Mode (Ollama Unavailable)

> **BARU**: Aplikasi inti tetap jalan jika AI lambat/down. Lihat GLOSSARY.md §10 LLM prompt versioning.

**Failure Scenarios**:
1. Ollama container down (`503 MODEL_UNAVAILABLE`)
2. GPU OOM / model loading timeout
3. Queue depth > 10 (overload)
4. P95 latency > 5000 ms

**Fallback Strategy**:

| Feature | Fallback Behavior | User-Facing Message |
| :--- | :--- | :--- |
| Tutor chat (24/7) | Return template deterministik berdasar `context_tp_id` dari tabel `scaffolding_templates` (seed saat migration) | "Maaf, asistenku sedang istirahat. Coba lagi nanti ya, atau hubungi guru." + tombol "Hubungi Guru" |
| Scaffolding hint (`SCAFFOLD_REQUIRED`) | Return hint generik dari `tp_metadata.scaffold_template` (field di Neo4j TP node) | "Coba pikirkan kembali konsep dasarnya. Kamu bisa!" (no personalisasi) |
| Parent weekly narrative (`/parent/activity-reflection`) | Template deterministik: `"[Student] aktif belajar minggu ini. {mastered_count} materi dikuasai, {in_progress_count} sedang dipelajari."` | Headline tanpa LLM |
| Modul ajar generator | Return `202 Accepted` dengan status `QUEUED` → retry saat Ollama UP | "Permintaan diterima, akan diproses saat sistem siap." |
| Hobby-aware rewrite | Skip rewrite, return ContentItem asli | Tidak ada user-facing message (transparent) |

**Implementation** (`backend_core/ai_engine/fallback.py`):
```python
def call_ollama_with_fallback(prompt, fallback_template=None, timeout_ms=4000):
    try:
        response = ollama.generate(prompt, timeout=timeout_ms)
        return {"success": True, "generated_via": "llm", "content": response}
    except (ConnectionError, TimeoutError, OllamaUnavailable):
        if fallback_template:
            return {"success": True, "generated_via": "fallback", "content": fallback_template}
        else:
            raise ModelUnavailableError("Ollama down and no fallback provided")
```

**Metrics**: Log `generated_via=fallback` count per hour ke Prometheus. Alert jika > 20% request pakai fallback selama 15 menit.

### H. Prompt Versioning & Audit

> **CANONICAL**: Lihat GLOSSARY.md §10 untuk naming convention.

Setiap LLM call wajib simpan `prompt_version` untuk reproducibility dan audit.

**Format**: `<use_case>_<variant>_v<number>`

**Storage**: 
* Prompt templates di `backend_core/ai_engine/prompts/<use_case>_v<number>.txt` (version controlled)
* Atau di `system_config` table dengan key `llm_prompt_<name>`, value = prompt string

**Logging**:
```python
# Setiap response LLM wajib punya metadata
response = {
    "content": "...",
    "metadata": {
        "prompt_version": "tutor_system_v1",
        "model": "llama3:8b-instruct",
        "temperature": 0.7,
        "generated_at": "2026-05-24T10:30:00Z",
        "token_count": 256,
        "latency_ms": 1850
    }
}
```

**Prompt Examples** (seed di migration):
* `tutor_system_v1` — System prompt untuk 24/7 tutor (§4.C)
* `scaffold_hint_v1` — Scaffolding untuk `SCAFFOLD_REQUIRED`
* `modul_ajar_scaffold_v2` — Modul ajar generator prompt
* `hobby_rewrite_v1` — Hobby-aware content rewrite (§5.A)
* `parent_headline_v1` — Weekly narrative untuk parent (§G fallback)

**Version Update**:
1. Buat file baru `tutor_system_v2.txt` dengan perubahan.
2. Update code reference `prompt_version="tutor_system_v2"`.
3. Deploy.
4. Monitor comparison v1 vs v2 (latency, handoff rate, user rating).

### I. Output Evaluator (Scaffold Mode)

> **BARU**: Deteksi jika tutor membocorkan jawaban akhir pada mode scaffolding.

**Problem**: Mode `SCAFFOLD_REQUIRED` seharusnya hanya beri hint, bukan jawaban. Tapi LLM bisa slip memberikan jawaban langsung.

**Evaluator** (`backend_core/ai_engine/scaffold_validator.py`):
```python
def validate_scaffold_output(output_text, content_item) -> bool:
    """Return True jika output AMAN (tidak bocor jawaban)"""
    # Rule 1: Jangan sebut angka jawaban final jika soal numeric
    if content_item.type == "NUMERIC":
        if re.search(r'\b' + re.escape(str(content_item.correct_answer)) + r'\b', output_text):
            return False  # Bocor jawaban
    
    # Rule 2: Jangan sebut opsi correct jika multiple choice
    if content_item.type == "MULTIPLE_CHOICE":
        correct_option = content_item.options[content_item.correct_index]
        if correct_option.lower() in output_text.lower():
            return False
    
    # Rule 3: Hindari phrase "jawabannya adalah", "hasilnya", "jadi X"
    forbidden_phrases = ["jawabannya adalah", "hasilnya", "jadi ", "jadi,"]
    if any(phrase in output_text.lower() for phrase in forbidden_phrases):
        return False  # Suspicious
    
    return True  # AMAN
```

**Action on Failure**:
* Jika evaluator return `False` → reject output, fallback ke template hint generik, log `safety_flags.answer_leaked=true`.
* Alert admin jika leak rate > 5% dalam 24 jam (prompt perlu diperbaiki).

**Test Case**:
```python
# tests/ai_engine/test_scaffold_validator.py
def test_scaffold_does_not_leak_answer():
    item = ContentItem(type="NUMERIC", question="2 + 3 = ?", correct_answer=5)
    leaked_output = "Jadi jawabannya adalah 5."
    safe_output = "Coba pikirkan: berapa 2 ditambah 3 langkah demi langkah?"
    
    assert validate_scaffold_output(leaked_output, item) == False
    assert validate_scaffold_output(safe_output, item) == True
```

### J. AI Disabled Mode (Global Kill Switch)

> **BARU**: Mode maintenance/emergency untuk disable semua AI features tanpa break aplikasi inti.

**Trigger**: `system_config` table → `llm_tutor_enabled=false`, `llm_modul_ajar_enabled=false`, `llm_rewrite_enabled=false`.

**Behavior per Feature**:

| Feature | AI Enabled | AI Disabled |
| :--- | :--- | :--- |
| Quiz flow (evaluate + next-content) | BKT + scaffolding hint LLM | BKT saja, skip scaffolding (langsung `CONTINUE_PRACTICE`) |
| Tutor chat button | Visible + functional | Hidden atau disabled state "Sementara tidak tersedia" |
| Parent weekly report | LLM headline | Template deterministik (§G fallback) |
| Modul ajar generator | Functional | Return `503 SERVICE_UNAVAILABLE` "Fitur sedang maintenance" |
| Hobby-aware rewrite | Active | Skip, return ContentItem asli |

**Implementation**:
```python
# backend_core/config.py
class Config:
    @property
    def llm_tutor_enabled(self) -> bool:
        return system_config_repo.get("llm_tutor_enabled", default=True)
    
    @property
    def llm_modul_ajar_enabled(self) -> bool:
        return system_config_repo.get("llm_modul_ajar_enabled", default=True)

# backend_core/api/tutor.py
@router.post("/chat")
def tutor_chat(...):
    if not config.llm_tutor_enabled:
        raise HTTPException(503, detail="Tutor chat sementara tidak tersedia.")
    # ... proceed
```

**Use Case**: 
* Ollama maintenance/upgrade.
* GPU hardware issue.
* Pilot phase conserve GPU for core eval only, disable nice-to-have features.

---

## 5. PERSONALISASI HOBI-AWARE (RAG INGESTION untuk SOAL)

Janji utama Executive Summary §3: "visualisasi pecahan menggunakan takaran resep kue" untuk siswa hobi memasak. Diimplementasikan sebagai **rewrite layer** di atas ContentItem statis.

### A. Algoritma `rewrite_content_for_student`

```python
def rewrite_for_student(content_item, student_id) -> RewrittenContent:
    profile = repo.affective_profile(student_id)
    interest = pick_top_interest(profile.interest_vector)  # mis. "MEMASAK"

    cache_key = f"rewrite:{content_item.id}:{interest}"
    if cached := redis.get(cache_key):
        return cached

    prompt = build_rewrite_prompt(content_item, interest)
    output = ollama_generate(model="llama3:8b-instruct", prompt=prompt, temperature=0.3)
    validated = validator.ensure_tp_alignment(content_item.tp_id, output)
    redis.set(cache_key, validated, ex=86400)
    return validated
```

### B. Validator Esensi TP
Output LLM **wajib** lulus tiga check:
1. Mengandung minimal satu konsep kunci dari `content_item.required_concepts` (string match).
2. Tidak mengubah jenis soal (numeric → tetap numeric; pilihan ganda → tetap pilihan ganda; jumlah opsi konsisten).
3. Tidak menyebut nama/alamat siswa.

Jika gagal, fallback ke ContentItem asli; tulis `audit_events` `action='RAG_REWRITE_FAILED'`.

### C. Update `interest_vector`
Algoritma sederhana:
* Tanya 5 pertanyaan opsional saat onboarding aplikasi siswa (Doc 05 / 11).
* Naikkan bobot ketika siswa menyelesaikan ContentItem dengan tag `interest_match` cocok dan mencapai mastery.
* Decay bobot 5% per minggu untuk hindari "stuck" pada hobi lama.
* Maksimal 5 interest aktif per siswa; weight dinormalisasi ke jumlah 1.

### D. Update `ai_calculated_focus_score`
* Hitung dari `student_quiz_logs.response_time_seconds` window 7 hari.
* `focus_score = clip(1 - (stdev_response_time / mean_response_time), 0.0, 1.0)`.
* Score < 0.3 → tampilkan reminder break di UI siswa (lihat Doc 05).

---

## 6. INTEGRASI DENGAN MATCHMAKER ENGINE

Diagram alir ringkas:

```
MatchmakerEngine.evaluate()
   │
   ├─ status CONTINUE_PRACTICE → call rewrite_for_student(next_content)
   │
   ├─ status SCAFFOLD_REQUIRED  → POST internal /scaffold/generate
   │                              (server-only endpoint, not exposed publicly)
   │
   └─ misconception != None     → tambahkan `misconception_name` ke prompt scaffold
```

---

## 7. KONFIGURASI OLLAMA & MODEL DOWNLOAD

```bash
docker exec -it aleta_ollama ollama pull llama3:8b-instruct
docker exec -it aleta_ollama ollama pull phi3:mini
docker exec -it aleta_ollama ollama pull nomic-embed-text

# Inisialisasi koleksi Qdrant
curl -X PUT http://aleta_vector_db:6333/collections/aleta_curriculum \
  -H 'Content-Type: application/json' \
  -d '{"vectors": {"size": 768, "distance": "Cosine"}}'
```

---

## 8. RELEASE GATE

Sebelum RAG/Tutor aktif di production, wajib:
* Red-team prompt injection (minimal 30 skenario di `tests/security/prompt_injection_corpus.md`).
* P95 latency end-to-end ≤ 3.5 detik di GPU node yayasan.
* Test handoff "TUTOR_HANDOFF_REQUIRED" memunculkan notifikasi guru < 30 detik.
* Tabel `tutor_messages` dipastikan masuk policy retensi 90 hari (Doc 07 §E).
