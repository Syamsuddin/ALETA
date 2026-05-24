---
doc: "02"
title: "Adaptive Engine Spec"
scope: "BKT math, ALETA_BKT_Engine, MatchmakerEngine state machine (NORMAL/IN_REMEDIATION/RETURNING), per-TP calibration"
key_entities: [ALETA_BKT_Engine, MatchmakerEngine, remediation_stack, p_init, p_transit, p_guess, p_slip]
depends_on: ["01", "03"]
loaded_by_tasks: [T-201, T-202, T-208]
---

# FILE: 02_ADAPTIVE_ENGINE_SPEC.md
# PROJECT ALETA: ADAPTIVE ENGINE & LEARNING LOGIC SPECIFICATION

## 1. PENDAHULUAN & PARADIGMA UTAMA
Dokumen ini mendefinisikan spesifikasi teknis untuk komponen inti kecerdasan buatan dalam ALETA: **The Matchmaker & Micro-Remediation Engine**.

Mesin ini menggunakan kombinasi dua algoritma utama pada Tahun 1–2 deployment:
1.  **Bayesian Knowledge Tracing (BKT):** Untuk memprediksi probabilitas penguasaan siswa terhadap suatu Tujuan Pembelajaran (TP) secara *real-time* berdasarkan riwayat jawaban.
2.  **Rule-Based Dependency Rerouting (Multi-Step):** Mengalihkan jalur belajar secara otomatis mundur ke materi prasyarat (bahkan lintas jenjang) ketika sistem mendeteksi kegagalan berulang akibat miskonsepsi kronis, dan **otomatis kembali ke TP utama** setelah prasyarat dikuasai.

### Catatan tentang Deep Reinforcement Learning
`00_EXECUTIVE_SUMMARY.md` menyebut "Deep Reinforcement Learning" sebagai bagian visi jangka panjang. Untuk menghindari over-promise, posisi resmi:

* **Tahun 1–2 (Pilot & Integrasi):** BKT + Rule-Based Rerouting (dokumen ini).
* **Tahun 3+ (Full Deployment):** Eksplorasi DRL untuk *policy learning* pemilihan ContentItem optimal berbasis riwayat afektif siswa. Spesifikasi resmi DRL akan ditulis sebagai dokumen terpisah (`18_DRL_POLICY_ENGINE.md`) saat fase pilot menyediakan minimal 1 tahun log lengkap. **Sampai dokumen tersebut ada, jangan generasikan kode DRL.**

---

## 2. FORMULASI MATEMATIKA: BAYESIAN KNOWLEDGE TRACING (BKT)
Setiap Tujuan Pembelajaran (TP) pada profil siswa diwakili oleh 4 parameter probabilitas laten:

*   $P(L_0)$ atau `p_init`: Probabilitas awal siswa sudah menguasai materi sebelum latihan dimulai.
*   $P(T)$ atau `p_transit`: Probabilitas siswa berpindah dari kondisi "belum menguasai" menjadi "menguasai" setelah melihat satu materi/soal.
*   $P(G)$ atau `p_guess`: Probabilitas siswa menjawab BENAR padahal BELUM menguasai materi (faktor beruntung).
*   $P(S)$ atau `p_slip`: Probabilitas siswa menjawab SALAH padahal SUDAH menguasai materi (faktor kecerobohan).

### Rumus Pembaruan Probabilitas (Kondisi Kontekstual)
Ketika siswa memberikan respons terhadap sebuah soal, sistem akan memperbarui probabilitas penguasaan saat ini ($P(L_t)$) dengan aturan Bayes:

#### Jika Jawaban SISWA = BENAR ($A_t = 1$):
$$P(L_t | A_t=1) = \frac{P(L_{t-1}) \cdot (1 - P(S))}{P(L_{t-1}) \cdot (1 - P(S)) + (1 - P(L_{t-1})) \cdot P(G)}$$

#### Jika Jawaban SISWA = SALAH ($A_t = 0$):
$$P(L_t | A_t=0) = \frac{P(L_{t-1}) \cdot P(S)}{P(L_{t-1}) \cdot P(S) + (1 - P(L_{t-1})) \cdot (1 - P(G))}$$

#### Langkah Prediksi Masa Depan (Transisi Kognitif):
Setelah memperbarui data berdasarkan jawaban di atas, hitung probabilitas penguasaan untuk langkah soal berikutnya ($P(L_{t+1})$):
$$P(L_{t+1}) = P(L_t | A_t) + (1 - P(L_t | A_t)) \cdot P(T)$$

*Threshold Kelulusan:* Seorang siswa dinyatakan **LULUS / MENGUASAI** sebuah TP jika nilai $P(L_{t+1}) \ge 0.85$.

---

## 3. LOGIKA REROUTING REMEDIAL LINTAS JENJANG
Ketika siswa terjebak pada sebuah materi dan nilai $P(L)$ terus menurun di bawah batas kritis ($P(L) < 0.20$), sistem akan menghentikan kuis dan memicu fungsi `trigger_remediation_routing`.


```

```
              ┌─────────────────────────────────┐
              │ Siswa menjawab soal pada TP 'X'  │
              └────────────────┬────────────────┘
                               ▼
                   [ Apakah Jawaban Benar? ]
                     │                   │
                 (Ya)│               (Tidak)
                     ▼                   ▼
             Update BKT P(L)      Update BKT P(L)
                     │                   │
          [ Apakah P(L) >= 0.85? ]  [ Apakah P(L) < 0.20? ]
                │          │              │          │
            (Ya)│      (Tidak)        (Ya)│      (Tidak)
                ▼          ▼              ▼          ▼
           TP Mastered!  Soal Lanjut   REROUTING   Soal Lanjut
           Buka Akses    ke Level-t+1  Cari Node   ke Level-t+1
           Next ATP                    Prasyarat

```

```

---

## 4. KODE IMPLEMENTASI PYTHON (SIAP KONSUMSI VIBE CODING)
Berikut adalah modul Python mandiri yang mengimplementasikan BKT Engine, **multi-step remediation state machine**, dan logika penentuan rute belajar. Salin kode ini ke `ai_engine/ai_engine/adaptive_engine.py` (lihat `15_PROJECT_STRUCTURE.md` §4 untuk struktur lengkap service `ai_engine/`).

```python
# ai_engine/ai_engine/adaptive_engine.py
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Protocol


# ---------------------------------------------------------------------------
# 4.1 BKT Engine dengan parameter per-TP (calibrated)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class BKTParams:
    """Parameter BKT untuk satu TP. Default global dipakai sebagai cold-start."""
    p_init: float = 0.15
    p_transit: float = 0.20
    p_guess: float = 0.20
    p_slip: float = 0.10


class BKTParamProvider(Protocol):
    """Kontrak repository — implementasi production membaca tabel
    `aleta_core.tp_bkt_params` (lihat 03_DATABASE_SCHEMA_MULTI_TENANTS.md §3)."""
    def get_params(self, tp_id: str) -> BKTParams: ...


class StaticBKTParamProvider:
    """Implementasi memori untuk testing & cold start."""

    DEFAULTS = BKTParams()

    def __init__(self, overrides: Optional[Dict[str, BKTParams]] = None):
        self._overrides = overrides or {}

    def get_params(self, tp_id: str) -> BKTParams:
        return self._overrides.get(tp_id, self.DEFAULTS)


class ALETA_BKT_Engine:
    # ⚠️ DEFAULT PILOT — NOT FINAL SCIENTIFIC VALUES
    # Threshold ini adalah starting point untuk pilot. Setelah 3-6 bulan data real,
    # lakukan kalibrasi per-TP menggunakan data assessment_attempts.
    # Lihat GLOSSARY.md §6 untuk detail kalibrasi.
    THRESHOLD_MASTERY = 0.85   # P(L) ≥ ini → MASTERY_ACHIEVED
    THRESHOLD_REMEDIAL = 0.20  # P(L) < ini → REROUTE_TO_PREREQUISITE

    def __init__(self, params_provider: BKTParamProvider):
        self.params_provider = params_provider

    def update_knowledge_state(self, tp_id: str, current_p_l: float, is_correct: bool) -> float:
        params = self.params_provider.get_params(tp_id)

        if is_correct:
            numerator = current_p_l * (1 - params.p_slip)
            denominator = numerator + ((1 - current_p_l) * params.p_guess)
        else:
            numerator = current_p_l * params.p_slip
            denominator = numerator + ((1 - current_p_l) * (1 - params.p_guess))

        # Lindungi dari division-by-zero pada nilai ekstrem (>0.9999 atau <0.0001)
        p_posterior = numerator / denominator if denominator > 0 else current_p_l
        next_p_l = p_posterior + (1 - p_posterior) * params.p_transit
        return round(min(max(next_p_l, 0.0001), 0.9999), 4)


# ---------------------------------------------------------------------------
# 4.2 Multi-step Remediation State Machine
# ---------------------------------------------------------------------------

class SessionState(str, Enum):
    NORMAL = "NORMAL"
    IN_REMEDIATION = "IN_REMEDIATION"
    RETURNING_TO_MAIN = "RETURNING_TO_MAIN"


@dataclass
class StudentSession:
    """Snapshot satu sesi belajar. Wajib dipersist ke `student_session_state`
    (lihat 03_DATABASE_SCHEMA_MULTI_TENANTS.md §3.G) supaya bisa di-resume."""
    student_id: str
    primary_tp_id: str            # TP utama yang sedang dikejar siswa
    current_tp_id: str            # TP yang aktif saat ini (bisa = primary atau prerequisite)
    current_p_l: float
    state: SessionState = SessionState.NORMAL
    remediation_stack: List[str] = field(default_factory=list)  # LIFO: TP utama di dasar


class GraphClient(Protocol):
    def fetch_immediate_prerequisite(self, tp_id: str) -> Optional[str]: ...
    def fetch_active_misconception(self, tp_id: str) -> Optional[Dict[str, Any]]: ...


@dataclass
class EvaluationOutcome:
    status: str
    next_action: str
    updated_p_l: float
    target_next_tp_id: str
    session: StudentSession
    misconception: Optional[Dict[str, Any]] = None
    message: str = ""


class MatchmakerEngine:
    """Mengintegrasikan BKT, dependency rerouting, dan state machine kembali-ke-main."""

    def __init__(self, bkt: ALETA_BKT_Engine, graph: GraphClient):
        self.bkt = bkt
        self.graph = graph

    def evaluate(self, session: StudentSession, is_correct: bool) -> EvaluationOutcome:
        updated_p_l = self.bkt.update_knowledge_state(
            session.current_tp_id, session.current_p_l, is_correct
        )
        session.current_p_l = updated_p_l

        if updated_p_l >= ALETA_BKT_Engine.THRESHOLD_MASTERY:
            return self._handle_mastery(session, updated_p_l)

        if updated_p_l < ALETA_BKT_Engine.THRESHOLD_REMEDIAL:
            return self._handle_remediation_trigger(session, updated_p_l)

        return EvaluationOutcome(
            status="CONTINUE_PRACTICE",
            next_action="FETCH_NEXT_ITEM_SAME_TP",
            updated_p_l=updated_p_l,
            target_next_tp_id=session.current_tp_id,
            session=session,
            message="Lanjutkan latihan dengan variasi soal.",
        )

    # --- handlers -----------------------------------------------------------

    def _handle_mastery(self, session: StudentSession, updated_p_l: float) -> EvaluationOutcome:
        # Apakah TP yang baru saja dikuasai adalah TP remedial?
        if session.state == SessionState.IN_REMEDIATION and session.remediation_stack:
            session.remediation_stack.pop()  # buang TP remedial yang baru lulus
            if session.remediation_stack:
                # masih ada lapisan remedial di atasnya → lanjut naik
                session.current_tp_id = session.remediation_stack[-1]
                session.state = SessionState.IN_REMEDIATION
                return EvaluationOutcome(
                    status="REMEDIAL_STEP_CLEARED",
                    next_action="ASCEND_TO_PARENT_REMEDIAL",
                    updated_p_l=updated_p_l,
                    target_next_tp_id=session.current_tp_id,
                    session=session,
                    message="Bagus! Naik satu lapis menuju materi sebelumnya.",
                )
            # stack kosong → kembali ke primary TP
            session.current_tp_id = session.primary_tp_id
            session.state = SessionState.RETURNING_TO_MAIN
            # Reset p_l primary tidak otomatis; backend memuat ulang nilai
            # terakhir dari `student_cognitive_passports`.
            return EvaluationOutcome(
                status="REMEDIATION_COMPLETED",
                next_action="RETURN_TO_PRIMARY_TP",
                updated_p_l=updated_p_l,
                target_next_tp_id=session.primary_tp_id,
                session=session,
                message="Kamu sudah siap melanjutkan materi utama!",
            )

        # Mastery murni pada TP utama
        session.state = SessionState.NORMAL
        return EvaluationOutcome(
            status="MASTERY_ACHIEVED",
            next_action="UNLOCK_NEXT_ATP",
            updated_p_l=updated_p_l,
            target_next_tp_id=session.current_tp_id,
            session=session,
            message="Selamat! Buka materi berikutnya pada ATP.",
        )

    def _handle_remediation_trigger(self, session: StudentSession, updated_p_l: float) -> EvaluationOutcome:
        prerequisite = self.graph.fetch_immediate_prerequisite(session.current_tp_id)
        misconception = self.graph.fetch_active_misconception(session.current_tp_id)

        if not prerequisite:
            # Tidak ada prerequisite → fallback ke scaffolding hint murni
            return EvaluationOutcome(
                status="SCAFFOLD_REQUIRED",
                next_action="REQUEST_LLM_SCAFFOLD",
                updated_p_l=updated_p_l,
                target_next_tp_id=session.current_tp_id,
                session=session,
                misconception=misconception,
                message="Sudah di akar prasyarat. Minta bantuan tutor AI.",
            )

        # Push prerequisite ke stack dan switch state
        if session.state != SessionState.IN_REMEDIATION:
            session.remediation_stack.append(session.current_tp_id)
        session.remediation_stack.append(prerequisite)
        session.current_tp_id = prerequisite
        session.state = SessionState.IN_REMEDIATION

        return EvaluationOutcome(
            status="REMEDIAL_TRIGGERED",
            next_action="REROUTE_TO_PREREQUISITE",
            updated_p_l=updated_p_l,
            target_next_tp_id=prerequisite,
            session=session,
            misconception=misconception,
            message="Mari kita perkuat materi prasyarat terlebih dulu.",
        )


# ---------------------------------------------------------------------------
# 4.3 Contoh penggunaan (runnable)
# ---------------------------------------------------------------------------

class _FakeGraph:
    """Mock graph untuk smoke test. Production memakai Neo4j driver."""
    _PREREQ_CHAIN = {
        "TP_MAT_7_ALJABAR": "TP_MAT_6_PERSAMAAN",
        "TP_MAT_6_PERSAMAAN": "TP_MAT_4_OPERASI",
        "TP_MAT_4_OPERASI": "TP_MAT_TK_COUNT",
        "TP_MAT_TK_COUNT": None,
    }

    def fetch_immediate_prerequisite(self, tp_id: str) -> Optional[str]:
        return self._PREREQ_CHAIN.get(tp_id)

    def fetch_active_misconception(self, tp_id: str) -> Optional[Dict[str, Any]]:
        return {"id": "MIS_OP_ORDER", "name": "Urutan operasi terbalik"} if tp_id == "TP_MAT_7_ALJABAR" else None


if __name__ == "__main__":
    bkt = ALETA_BKT_Engine(StaticBKTParamProvider())
    matchmaker = MatchmakerEngine(bkt, _FakeGraph())

    session = StudentSession(
        student_id="STUDENT_007",
        primary_tp_id="TP_MAT_7_ALJABAR",
        current_tp_id="TP_MAT_7_ALJABAR",
        current_p_l=0.30,
    )

    print(f"[start] primary={session.primary_tp_id} p_l={session.current_p_l}")
    for trial in range(1, 8):
        outcome = matchmaker.evaluate(session, is_correct=False)  # salah terus → reroute mundur
        print(f"[t={trial}] state={session.state.value} curr={session.current_tp_id} "
              f"p_l={outcome.updated_p_l} action={outcome.next_action}")
        if outcome.next_action in {"REQUEST_LLM_SCAFFOLD", "RETURN_TO_PRIMARY_TP"}:
            break

```

### Properti Kunci State Machine
* `remediation_stack` adalah LIFO; elemen paling bawah selalu `primary_tp_id`.
* Setelah `REMEDIATION_COMPLETED`, backend wajib **memuat ulang `current_p_l`** primary dari `student_cognitive_passports` (jangan pakai nilai remedial). Lihat `student_session_state` table di `03_…` §3.G.
* Status `SCAFFOLD_REQUIRED` (ketika sudah tidak ada prerequisite) memicu LLM tutor — lihat `09_RAG_AND_TUTOR_SPEC.md`.

---

## 6. KALIBRASI PARAMETER BKT PER-TP (PRODUCTION TUNING)

Default global di atas (`p_init=0.15`, dst) hanya dipakai untuk **cold start**. Saat log jawaban terkumpul, parameter per-TP harus dikalibrasi.

### A. Sumber data kalibrasi
Tabel `unit_*.student_quiz_logs` (Doc 03 §3) memberi tuple `(student_id, tp_id, is_correct, response_time_seconds, timestamp)`.

### B. Algoritma kalibrasi (batch nightly)
1. Untuk setiap TP dengan ≥ 200 attempt unik per kohort kelas, jalankan EM (Expectation-Maximization) untuk fit `(p_init, p_transit, p_guess, p_slip)` yang memaksimalkan likelihood log.
2. Constraint sanity (industry standard):
   * `p_guess ≤ 0.30`
   * `p_slip ≤ 0.10`
   * `p_transit ∈ [0.05, 0.40]`
3. Tulis hasil ke `aleta_core.tp_bkt_params` (Doc 03 §3.F) bersama `sample_size` dan `last_calibrated_at`.
4. Engine produksi (`StaticBKTParamProvider`-equivalent) membaca tabel ini lazily dengan cache 30 menit.

### C. Difficulty rating ContentItem
Properti `difficulty_rating` (Doc 01 §2.H) dihitung paralel: untuk satu ContentItem,
`difficulty = 1 − (jumlah_jawaban_benar / total_attempt)` dalam window 30 hari terakhir,
diperhalus dengan Laplace smoothing `(+1, +2)` jika sample kecil.

### D. Penambahan `response_time_seconds` ke fitur risk
Walau formula BKT inti tidak memakainya, sinyal ini dipakai di dua tempat:
* **Red Flag detector** (Doc 06 §2) — slowdown drastis = sinyal kebingungan.
* **Difficulty re-rating** — soal yang lulus tinggi tapi rerata response time > p95 ditandai *misleading easy*.

---

## 7. INTEGRASI DENGAN MISCONCEPTION MAP

Saat `evaluate()` mengembalikan `misconception != None`, backend wajib:
1. Insert/update baris di `aleta_core.student_misconceptions` (Doc 03 §3.H) — cumulative count.
2. Forward `misconception.id` ke prompt LLM scaffolding (Doc 09) sebagai context tag.
3. Catat ke `audit_events` dengan `risk_level='MEDIUM'` agar pola lintas-tahun bisa dianalisis tim kurikulum yayasan.

---

## 8. REKOMENDASI GENERASI KONTEN BERBASIS CONTEXT (LLM-RAG INTEGRATION)

> **Spesifikasi lengkap RAG arsitektur dipindahkan ke `09_RAG_AND_TUTOR_SPEC.md`.** Bagian di bawah hanya menampilkan prompt template singkat yang dipakai langsung oleh `MatchmakerEngine` saat status `CONTINUE_PRACTICE` atau `SCAFFOLD_REQUIRED`.

```ini
[SYSTEM PROMPT FOR LOCAL OLLAMA TUTOR]
Kamu adalah modul pembuat perancah (scaffolding prompt generator) pada aplikasi ALETA.
Tugasmu adalah membantu siswa yang macet pada Tujuan Pembelajaran (TP) berikut: {current_tp_id}.
Berdasarkan profil psikososial siswa, buatkan satu petunjuk penyelesaian soal matematika tanpa memberikan bocoran jawaban akhir.

Konteks Hobi Siswa: {student_interest_context}
Miskonsepsi Terdeteksi: {misconception_name}
Tingkat Kesulitan: Turunkan 10% lebih mudah dari soal sebelumnya.
Bahasa: Gunakan bahasa Indonesia yang ramah, santun, dan memotivasi khas guru pamong.

```

---