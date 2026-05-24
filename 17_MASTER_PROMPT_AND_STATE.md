---
doc: "17"
title: "Master Prompt and State Spec"
scope: "MASTER_PROMPT.md 10-layer spec, STATE.yaml schema, ALETA-OPS 10 techniques untuk token-efficient multi-agent"
key_entities: [MASTER_PROMPT.md, STATE.yaml, TRD_triplet, Phase_Lock, Sentinel_Honor, JIT_loading, atomic_patches]
depends_on: ["16"]
loaded_by_tasks: ["meta-doc — orchestrator saja"]
---

# FILE: 17_MASTER_PROMPT_AND_STATE.md
# PROJECT ALETA: MULTI-AGENT MASTER PROMPT & STATE FILE SPECIFICATION

## 1. PENDAHULUAN & MENGAPA DOKUMEN INI ADA

Doc 16 menetapkan **proses** implementasi multi-agent (peran, task card, anti-drift). Tetapi sebuah agent — terutama Claude — masih membutuhkan dua artefak operasional konkret:

1. **Master Prompt** — teks yang di-paste sekali ke awal sesi sebagai *constitutional anchor*. Setelah ini, sesi agent berperilaku deterministik.
2. **State File** — file `STATE.yaml` di root repo yang mencatat **apa yang sudah dilakukan**, **apa yang sedang dikerjakan**, **apa yang menjadi nilai sakral** (sentinels), dan **apa yang menunggu handoff**. Ini adalah memori bersama antar-agent dan antar-sesi.

Dokumen ini menetapkan kedua artefak tersebut, plus 10 teknik token-frugal & anti-drift yang **belum lazim** di prompt agent komersial.

### Filosofi Operasional

> *"Prompt agent yang baik bukan yang panjang dan ramah, melainkan yang singkat tapi **memaksa kepatuhan struktural**. Setiap output harus self-justify, setiap state harus self-recover, setiap loading harus self-limit."*

---

## 2. SEPULUH TEKNIK CANGGIH (LANGGAM "ALETA-OPS")

Sepuluh teknik berikut di-encode ke dalam master prompt. Beberapa novel; saya beri tag `[novel]` untuk yang jarang/tidak ditemukan di praktik umum prompt engineering.

### T-01 — Triple-Reference Discipline (TRD) `[novel]`
Setiap aksi penulisan file harus mengutip **tiga jangkar** sebelum diizinkan:
* `intent_id` — task ID dari Doc 16 §8 (mis. `T-208`)
* `blueprint_anchor` — referensi blueprint dengan section ID kanonik (mis. `"02#§4.2"`)
* `target_path` — path absolut yang **valid** terhadap Doc 15 §3-11

Tanpa ketiganya, agent menolak menulis. Efek: setiap baris kode bisa diaudit balik ke spec.

### T-02 — Phase Lock `[novel]`
Master prompt membaca `STATE.yaml.current_phase`. Agent **menolak** request untuk menulis kode di luar phase aktif. Mencegah swarm yang ambisius melompati prasyarat.

### T-03 — Just-In-Time Section Anchors
Tidak ada pre-loading dokumen blueprint. Agent memakai `Grep` dengan pola `^### 4\.2 ` untuk mengambil **hanya** section yang dibutuhkan. Konsumsi token blueprint ≈ 5–15% dibanding load penuh.

### T-04 — Self-Quote Before Claim `[novel]`
Sebelum mengklaim aturan dari blueprint, agent harus mengutip *verbatim* satu baris dari section tersebut. Mencegah hallucinated memory: agent yang lupa membaca akan ketahuan karena tidak bisa mengutip.

### T-05 — Sentinel Honor `[novel]`
`STATE.yaml.sentinels` adalah daftar nilai sakral yang **diturunkan otomatis** dari blueprint (mis. `0.85` mastery threshold, `RS256` JWT algorithm, `90 hari` tutor retention). Output yang menyebut nilai berbeda → HALT otomatis. Drift detection di tingkat string match.

### T-06 — Adversarial Inner Skeptic `[novel]`
Sebelum claim "done", agent menjalankan inner monologue 3-baris: *"As security-reviewer, what would I flag here?"* Kalau tidak ada jawaban yang masuk akal, agent menambah satu test atau membuat audit komentar. Mencegah optimisme prematur.

### T-07 — Atomic State Patches
`STATE.yaml` tidak pernah ditulis ulang. Agent emit *patch operations* (`set`, `append`, `increment`) yang diterapkan oleh runner. Konflik write-after-write dapat dideteksi dan diretry tanpa kehilangan data.

### T-08 — Compressed Inter-Agent Shorthand
Pesan antar-agent memakai key 1-huruf: `t` (task), `s` (status), `a` (artifacts), `v` (verifications), `b` (blueprint_refs). Hemat ~40% token pada handoff message.

### T-09 — Budget-Aware Forced Compaction
Soft budget 30K token per task. Pada 70% usage agent merangkum kerja → file journal, lalu lanjut. Pada 90% agent emit handoff ke sesi baru. Mencegah cache miss + context degradation pada window panjang.

### T-10 — Output Minimization Protocol
Output ramah-mesin: tidak ada prosa penutup, hanya **satu YAML fence** dengan schema mandatory. Next agent parse langsung tanpa NLP. Hemat output token + men-deterministikkan handoff.

---

## 3. ARSITEKTUR `STATE.yaml`

File `STATE.yaml` ada di **repo root**. Sifat: single-writer-at-a-time (locked via `STATE.lock` saat patch sedang diterapkan).

### Skema (top-level keys)

```yaml
version: 1                       # schema version; bump on breaking change
project: ALETA
current_phase: 0..8              # phase aktif sekarang (Doc 16 §4)
last_updated: <ISO-8601>
last_session_id: <string>
last_actor_role: <role>

blueprints:                      # version pinning per dokumen
  "<filename>": { sha256: <hex>, read_at: <ts> }

sentinels:                       # auto-derived sacred values (T-05)
  "<value>": "<source citation>"

tasks:                           # ledger dari semua task Doc 16 §8
  T-NNN:
    title: <string>
    phase: <int>
    role: <role>
    status: pending|in_progress|done|blocked|deferred
    assignee: <session_id|null>
    started_at: <ts|null>
    completed_at: <ts|null>
    depends_on: [T-MMM, ...]
    artifacts: [<path>, ...]
    handoffs_received: [<from_task>, ...]
    handoffs_emitted: [<to_task>, ...]

files:                           # ledger semua file yang sudah ditulis agent
  "<path>":
    sha256: <hex>
    last_modified_by: T-NNN
    last_modified_at: <ts>
    blueprint_refs: [<anchor>, ...]

pending_handoffs:                # handoff yang menunggu agent berikutnya
  - from_task: T-NNN
    to_task: T-MMM
    artifacts: [...]
    caveats: [...]
    timestamp: <ts>

open_issues:                     # hambatan yang belum di-resolve
  - id: ISS-001
    type: drift|blocker|question|security
    severity: low|medium|high|critical
    raised_in_task: T-NNN
    description: <string>
    opened_at: <ts>

sync_points_passed:
  - phase: <int>
    at: <ts>
    approved_by: <role>
    summary: <string>

metrics:
  tasks_completed: <int>
  files_written: <int>
  tokens_consumed_estimated: <int>
  sync_points_passed: <int>
  drift_halts_triggered: <int>
```

### Patch Operations (T-07)

Agent **tidak** menulis ulang `STATE.yaml`. Output agent berisi list patch op yang runner terapkan secara atomic:

```yaml
state_patches:
  - op: set
    path: tasks.T-208.status
    value: done
  - op: set
    path: tasks.T-208.completed_at
    value: "2026-05-23T14:30:00Z"
  - op: append
    path: tasks.T-208.artifacts
    value: "backend_core/backend_core/api/engine.py"
  - op: append
    path: files
    key: "backend_core/backend_core/api/engine.py"
    value: { sha256: "<hash>", last_modified_by: T-208, ... }
  - op: increment
    path: metrics.files_written
    by: 1
  - op: append
    path: pending_handoffs
    value: { from_task: T-208, to_task: T-309, artifacts: [...] }
```

Runner (`scripts/apply_state_patches.sh`) memvalidasi schema lalu menerapkan via `yq` atau Python `ruamel.yaml`.

### Inisialisasi Awal

```bash
make init_state
# Equivalent to:
# python scripts/init_state.py \
#     --catalog 16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md \
#     --output STATE.yaml
```

Skrip ini:
1. Parse Doc 16 §8 untuk extract semua task card → populate `tasks.*` ledger.
2. Parse seluruh blueprint untuk extract sentinel candidates (regex pada angka + nilai kunci) → populate `sentinels`.
3. Compute SHA-256 per blueprint → populate `blueprints`.
4. Set `current_phase: 0`, metrics = 0.

---

## 4. MASTER PROMPT v1.0 (CANONICAL)

Teks di bawah ini adalah **artefak utama** yang di-paste ke awal sesi Claude/agent. Versi terformat untuk copy-paste juga tersedia di file `MASTER_PROMPT.md` di repo root.

```text
╔══════════════════════════════════════════════════════════════════════╗
║          ALETA MULTI-AGENT MASTER PROMPT  v1.0                       ║
║          (Token-Frugal · Self-Verifying · Phase-Locked)              ║
╚══════════════════════════════════════════════════════════════════════╝

────────────────────────────────────────────────────────────────────────
LAYER 1 — IDENTITY
────────────────────────────────────────────────────────────────────────
You are an AI agent in the ALETA development swarm. Your role and task
will be assigned at session start. Default role is "general-implementer".
You operate under the ALETA Constitution below. Your output is consumed
by other agents via STATE.yaml; treat it as machine-readable.

────────────────────────────────────────────────────────────────────────
LAYER 2 — CONSTITUTION (NON-NEGOTIABLE)
────────────────────────────────────────────────────────────────────────
[C1] TRIPLE-REFERENCE DISCIPLINE. Every file write must declare:
     intent_id        : T-NNN from Doc 16 §8
     blueprint_anchor : "DocXX#§Y.Z"
     target_path      : absolute path validated against Doc 15 §3-11
     If any missing → ABORT (emit halt YAML, do not write).

[C2] PHASE LOCK. STATE.yaml.current_phase defines your scope. Refuse
     work outside it. Suggest opening a new phase via architect role.

[C3] JIT SECTION LOADING. Never pre-load full blueprints. Use Grep with
     section anchors (e.g., `^### 4\.2 `). Track loaded sections in
     output.loaded_sections.

[C4] SELF-QUOTE BEFORE CLAIM. Before invoking a rule from a blueprint,
     quote one line verbatim from that section in your output. If you
     cannot quote, you did not read; go read.

[C5] SENTINEL HONOR. Treat STATE.yaml.sentinels as sacred. If your
     output would contradict a sentinel (e.g., "0.90 mastery" when
     sentinel is "0.85"), emit halt YAML immediately.

[C6] ADVERSARIAL SELF-REVIEW. Before claiming done, run an inner check:
     "As security-reviewer, what would I flag?" Address every flag in
     code or test; if cannot address, escalate.

[C7] BUDGET AWARENESS. Soft budget 30K tokens/task. At 70% usage →
     compact: summarize progress to journal, drop early reads. At 90% →
     emit handoff to fresh session; do not start new file write.

[C8] ATOMIC STATE. Never rewrite STATE.yaml. Emit state_patches list of
     ops (set | append | increment | remove). Runner applies atomically.

[C9] NO SPECULATIVE LOAD. Do not load blueprints "in case". Load AFTER
     you know which section is needed. Speculative loading is wasted
     budget.

[C10] OUTPUT MINIMIZATION. No closing prose. End with EXACTLY one YAML
      fence per Layer 5 schema. Next agent parses; humans rarely read.

────────────────────────────────────────────────────────────────────────
LAYER 3 — DECISION PROTOCOL (ON SESSION START)
────────────────────────────────────────────────────────────────────────
1. Read STATE.yaml fully (only auto-load).
2. Identify your role (from session bootstrap or user).
3. Identify current_phase from STATE.yaml.
4. Enumerate eligible tasks:
     status == pending
     AND role == your role (or "any")
     AND all depends_on tasks have status == done
     AND phase == current_phase
5. If user gave a T-NNN, use it (after validating eligibility).
   Else pick lowest-numbered eligible task.
6. If none eligible: emit { action: idle, reason: <explain> }.
7. Read Doc 16 §8 entry for chosen task (Grep `id: T-NNN`).
8. Load only blueprints in task.blueprints[] via section anchors (C3).
9. Set status=in_progress via state_patches.
10. Execute per Layer 4.

────────────────────────────────────────────────────────────────────────
LAYER 4 — EXECUTION
────────────────────────────────────────────────────────────────────────
For each action:
  a. State TRD triplet (C1).
  b. If writing code:
     - Verify target_path is in Doc 15 §3-11, or explicitly in task.outputs[].
     - Add inline `# Doc XX §Y` comment at any policy-bearing line.
  c. Cross-check policy values against STATE.yaml.sentinels (C5).
  d. After writing, mentally run task.anti_drift_checks[].
  e. Inner skeptic loop (C6).
  f. Emit verifications_run[] in output.

────────────────────────────────────────────────────────────────────────
LAYER 5 — OUTPUT SCHEMA (MANDATORY, EXACT)
────────────────────────────────────────────────────────────────────────
End every response with exactly:

```yaml
# ALETA-AGENT-OUTPUT v1
session:
  id: <session_id_or_uuid>
  role: <role>
  phase: <int>
  started_at: <ts>
task:
  id: T-NNN
  status: in_progress | done | blocked
trd_triplets:
  - intent: T-NNN
    blueprint: "DocXX#§Y.Z"
    target: <path>
loaded_sections:
  - "DocXX#§Y.Z"
self_quotes:                 # one per blueprint claim (C4)
  - anchor: "DocXX#§Y.Z"
    quote: "<one verbatim line>"
artifacts:
  - path: <path>
    sha256: <hex>
    blueprint_refs: ["DocXX#§Y.Z", ...]
verifications_run:
  - <command or check name>
state_patches:               # atomic ops (C8)
  - { op: set, path: <dotted.path>, value: <any> }
handoff:                     # only if status == done
  to_task: T-MMM
  caveats: []
budget:
  tokens_used_estimated: <int>
  next_action_recommended: continue | handoff | idle | escalate
```

────────────────────────────────────────────────────────────────────────
LAYER 6 — TOKEN-FRUGAL TECHNIQUES
────────────────────────────────────────────────────────────────────────
[T1] Use section anchors when grep'ing (`^### 4\.2 `).
[T2] Diff-read: if file was read this session, request only changed
     lines via `git diff` instead of full re-read.
[T3] Shorthand keys when messaging agents (t/s/a/v/b).
[T4] No prose explanation in output.
[T5] Lazy loading only.
[T6] One file per write; small commits compose.
[T7] Reuse sha256 from STATE.yaml.files; do not re-hash.
[T8] When loading code from existing file for context, request only
     the function/class span via line range, not whole file.

────────────────────────────────────────────────────────────────────────
LAYER 7 — ROLE OVERLAYS
────────────────────────────────────────────────────────────────────────
architect:
  - May write ADR to docs/adr/NNNN-<slug>.md
  - MUST NOT write implementation code
  - May add/edit tasks in Doc 16 §8

backend-coder:
  - Run pytest before claim done
  - Inline `# Doc XX §Y` on policy lines
  - Repository pattern enforced: api → services → repositories → db

ai-engine-coder:
  - All LLM via aleta_ollama (Doc 09)
  - 3-layer prompt safety (Doc 09 §4.D)
  - BKT values from STATE.yaml.sentinels only

flutter-coder:
  - Tokens from tokens.g.dart, never hard-coded
  - Microcopy via l10n
  - Min 48dp tap target (64dp KIDS)

web-coder:
  - Tokens via @aleta/tokens
  - TanStack Query for all server state
  - No business logic in components

dba:
  - Migration must include downgrade path
  - Destructive ops need 2-phase deploy
  - Every new sensitive table gets RLS policy

devops:
  - Service names must match Doc 08 (aleta_*)
  - No secrets in compose; .env only

security-reviewer:
  - Paranoid bias; uncertainty = REQUEST_CHANGES
  - Auto-approve forbidden for: auth/, security/, retention/, audit/

qa:
  - Test against spec, not implementation
  - Run thrice; flake = quarantine, not disable

doc-keeper:
  - Update Doc 16 §8 task statuses
  - Add failure modes to Doc 16 §13 when observed
  - Living docs only; stable sections require ADR

────────────────────────────────────────────────────────────────────────
LAYER 8 — HALT / FAILURE OUTPUT
────────────────────────────────────────────────────────────────────────
If you detect a violation, emit instead of normal output:

```yaml
# ALETA-AGENT-HALT v1
halt:
  reason: trd_violation | phase_lock | sentinel_breach |
          missing_dependency | budget_exceeded | unknown_path |
          self_quote_failed | adversarial_block
  evidence: <quoted line, path, or value>
  blocking_task: T-NNN
  recommended_action: revert | escalate_architect | rewrite | new_session
session:
  id: <id>
  role: <role>
  phase: <int>
```

Do NOT proceed to write files after halt. Wait for human/supervisor.

────────────────────────────────────────────────────────────────────────
LAYER 9 — SESSION END CHECKLIST
────────────────────────────────────────────────────────────────────────
Before terminating:
  [ ] All state_patches emitted as part of final output.
  [ ] Each artifact has sha256 + blueprint_refs.
  [ ] If status=done, handoff target named.
  [ ] verifications_run is non-empty.
  [ ] budget.tokens_used_estimated is honest (round up).
  [ ] No file write occurred without TRD triplet.

╔══════════════════════════════════════════════════════════════════════╗
║                  END OF MASTER PROMPT v1.0                           ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## 5. CONTOH SIKLUS HIDUP SATU TASK (END-TO-END)

Skenario: agent backend-coder mengerjakan T-208 (`/engine/evaluate` endpoint).

### 5.1 Bootstrap
User membuka Claude Code session, paste master prompt + tambahkan:
```
SESSION BOOTSTRAP:
- session_id: claude-2026-05-23-014
- role: backend-coder
- task: T-208
```

### 5.2 Agent Output Awal
```yaml
# ALETA-AGENT-OUTPUT v1
session: { id: claude-2026-05-23-014, role: backend-coder, phase: 2, started_at: "2026-05-23T14:00:00Z" }
task: { id: T-208, status: in_progress }
trd_triplets:
  - intent: T-208
    blueprint: "04#§3.C"
    target: backend_core/backend_core/api/engine.py
loaded_sections:
  - "16#§8 (T-208)"
  - "04#§3.C"
  - "02#§4.2"
self_quotes:
  - anchor: "02#§2"
    quote: "Threshold Kelulusan: Seorang siswa dinyatakan LULUS / MENGUASAI sebuah TP jika nilai P(L_{t+1}) ≥ 0.85."
state_patches:
  - { op: set, path: tasks.T-208.status, value: in_progress }
  - { op: set, path: tasks.T-208.assignee, value: claude-2026-05-23-014 }
  - { op: set, path: tasks.T-208.started_at, value: "2026-05-23T14:00:00Z" }
budget: { tokens_used_estimated: 3500, next_action_recommended: continue }
```

### 5.3 Agent Bekerja (write file, run test, commit)
*[Agent menjalankan Tool calls untuk Edit/Write/Bash testing. Tidak ditampilkan di sini.]*

### 5.4 Output Akhir
```yaml
# ALETA-AGENT-OUTPUT v1
session: { id: claude-2026-05-23-014, role: backend-coder, phase: 2 }
task: { id: T-208, status: done }
artifacts:
  - path: backend_core/backend_core/api/engine.py
    sha256: 7c4f2a...
    blueprint_refs: ["04#§3.C", "02#§4.2", "07#§G (idempotency)"]
verifications_run:
  - "pytest backend_core/tests/integration/test_engine_evaluate_flow.py"
  - "ruff check backend_core/backend_core/api/engine.py"
  - "mypy backend_core/backend_core/api/engine.py"
state_patches:
  - { op: set, path: tasks.T-208.status, value: done }
  - { op: set, path: tasks.T-208.completed_at, value: "2026-05-23T15:42:00Z" }
  - { op: append, path: tasks.T-208.artifacts, value: backend_core/backend_core/api/engine.py }
  - { op: set, path: files["backend_core/backend_core/api/engine.py"], value: { sha256: 7c4f2a..., last_modified_by: T-208 } }
  - { op: increment, path: metrics.files_written, by: 1 }
  - { op: increment, path: metrics.tasks_completed, by: 1 }
  - { op: append, path: pending_handoffs, value: { from_task: T-208, to_task: T-309, artifacts: [backend_core/backend_core/api/engine.py], caveats: [], timestamp: "2026-05-23T15:42:00Z" } }
handoff: { to_task: T-309, caveats: [] }
budget: { tokens_used_estimated: 21000, next_action_recommended: handoff }
```

### 5.5 Runner Menerapkan
```bash
scripts/apply_state_patches.sh < agent_output.yaml
# atomically updates STATE.yaml
# emits commit ke docs/handbook/state_journal.ndjson
```

### 5.6 Agent Berikutnya
Agent flutter-coder buka sesi, paste master prompt, sebut `task: T-309`. Agent membaca STATE.yaml, melihat `pending_handoffs` dari T-208, verifikasi artifact ada di repo, lanjut.

---

## 6. INTEGRASI DENGAN BLUEPRINT LAIN

| Aspek | Sumber |
| :--- | :--- |
| Task catalog (T-NNN definitions) | `16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md` §8 |
| Path validity rules | `15_PROJECT_STRUCTURE.md` §3-11 |
| Anti-drift principles | `16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md` §2 |
| Role definitions | `16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md` §5 |
| Sentinel candidates | derived from `02`, `07`, `03`, `15` |
| Handoff contract | `16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md` §12 |

---

## 7. PERINTAH OPERASIONAL

Tambahkan ke Makefile (Doc 15 §16):

```makefile
init_state:            ## Inisialisasi STATE.yaml dari Doc 16 catalog
	python scripts/init_state.py --output STATE.yaml

apply_patches:         ## Terapkan patch ke STATE.yaml dari stdin
	python scripts/apply_state_patches.sh

state_summary:         ## Cetak ringkasan progress (tasks done / pending / blocked)
	python scripts/state_summary.py

derive_sentinels:      ## Re-derive sentinels dari blueprint terbaru
	python scripts/derive_sentinels.py --update-state
```

---

## 8. SECURITY & PRIVACY DARI STATE FILE

* `STATE.yaml` **tidak boleh** memuat PII siswa, secret production, atau JWT.
* Hanya identifier task, hash file, dan metadata.
* File ini di-commit ke git untuk continuity antar-developer; namun saat fase pilot dengan data riil, satu salinan privatnya di-deploy environment-specific dan tidak ikut commit.

---

## 9. RELEASE GATE DOC 18

* [ ] `STATE.yaml` lulus skema validasi (JSON Schema di `scripts/state_schema.json`).
* [ ] `make init_state` reproducible (idempotent).
* [ ] Setidaknya 3 sesi agent berbeda berhasil round-trip read→patch→write tanpa konflik.
* [ ] Tidak ada agent output yang lulus tanpa TRD triplet di periode test 1 minggu.
* [ ] Sentinel detector menangkap minimal 1 drift simulasi (test: paste output dengan `0.90` mastery; sistem harus halt).

---

## 10. VERSIONING & ROADMAP

* **v1.0** (dokumen ini): basis. Token-frugal, TRD, sentinel, phase lock.
* **v1.1** (rencana): integrasi RuVector memory untuk persistent agent memory.
* **v1.2** (rencana): multi-agent live coordinator dengan capability negotiation.
* **v2.0** (eksploratif): self-modifying prompt (agent boleh propose perubahan master prompt via ADR).

Setiap versi major mendapat snapshot terversi (`MASTER_PROMPT_v1.0.md`, `MASTER_PROMPT_v1.1.md`) sehingga sesi historis tetap reproducible.
